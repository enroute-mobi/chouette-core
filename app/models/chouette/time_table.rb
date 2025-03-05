# frozen_string_literal: true

module Chouette
  class TimeTable < Referential::Model
    include ApplicationDaysSupport
    include ObjectidSupport
    include TimetableSupport
    has_metadata

    attr_accessor :skip_save_shortcuts

    def self.ransackable_attributes auth_object = nil
      column_names + _ransackers.keys
    end

    has_and_belongs_to_many :vehicle_journeys, :class_name => 'Chouette::VehicleJourney'
    has_many :routes, -> { distinct }, through: :vehicle_journeys, :class_name => 'Chouette::Route'
    has_many :lines, -> { distinct }, through: :routes, :class_name => 'Chouette::Line'

    has_many :dates, -> {order(:date)}, inverse_of: :time_table, :validate => :true, :class_name => "Chouette::TimeTableDate", dependent: :destroy
    has_many :periods, -> {order(:period_start)}, inverse_of: :time_table, :validate => :true, :class_name => "Chouette::TimeTablePeriod", dependent: :destroy

    belongs_to :calendar, optional: true # CHOUETTE-3247 failling specs
    belongs_to :created_from, class_name: 'Chouette::TimeTable', optional: true # CHOUETTE-3247 failing specs

    scope :overlapping, -> (period_range) do
      joins("
        LEFT JOIN time_table_periods ON time_tables.id = time_table_periods.time_table_id
        LEFT JOIN time_table_dates ON time_tables.id = time_table_dates.time_table_id
      ")
      .where("(time_table_periods.period_start <= :end AND time_table_periods.period_end >= :begin) OR (time_table_dates.date BETWEEN :begin AND :end)", {begin: period_range.begin, end: period_range.end})
    end

    scope :not_associated, -> {
      joins('LEFT JOIN "time_tables_vehicle_journeys" ON time_tables_vehicle_journeys.time_table_id = time_tables.id')
      .where("time_tables_vehicle_journeys.vehicle_journey_id is null")
    }

    scope :used, -> { joins(:vehicle_journeys).distinct }

    scope :empty, -> {
      left_joins(:periods, :dates).where(time_table_periods: {id: nil}, time_table_dates: {id: nil})
    }
    scope :without_periods, -> {
      left_joins(:periods).where(time_table_periods: {id: nil})
    }

    scope :by_text, ->(text) { text.blank? ? all : where('unaccent(time_tables.comment) ILIKE :t or lower(time_tables.objectid) LIKE :t', t: "%#{text.downcase}%") }

    def self.scheduled_on(date)
      day_order = date.wday == 0 ? 8 : date.wday + 1
      query = <<~SQL
        (int_day_types >> :day_order & 1 = 1
          AND :date between period_start and period_end
          AND (
            time_table_dates.id is null OR
            (NOT (date = :date AND in_out = false))
          )
        ) OR (date = :date AND in_out = true)
      SQL

      left_joins(:periods, :dates).where(query, date: date, day_order: day_order)
    end

    def self.shared_by_several_lines?
      joins(:routes).group(:id).having("count(distinct(line_id)) > 1").exists?
    end

    after_save :save_shortcuts

    def local_id
      "local-#{self.referential.id}-#{self.id}"
    end

    def checksum_attributes(db_lookup = true)
      [].tap do |attrs|
        attrs << self.int_day_types
        dates = self.dates
        dates += TimeTableDate.where(time_table_id: self.id) if db_lookup && !new_record?
        attrs << dates.map(&:checksum).map(&:to_s).uniq.sort
        periods = self.periods
        periods += TimeTablePeriod.where(time_table_id: self.id) if db_lookup && !new_record?
        attrs << periods.map(&:checksum).map(&:to_s).uniq.sort
      end
    end

    has_checksum_children TimeTableDate
    has_checksum_children TimeTablePeriod

    accepts_nested_attributes_for :dates, :allow_destroy => :true
    accepts_nested_attributes_for :periods, :allow_destroy => :true

    validates_presence_of :comment
    validates_associated :dates
    validates_associated :periods

    def self.applied_at_least_once_in(date_range)
      self.where(id: applied_at_least_once_in_ids(date_range))
    end

    def self.applied_at_least_once_in_ids(date_range)
      ids = Set.new
      date_range.each_slice(200) do |range|
        query =  <<-SQL
          WITH  dates AS (
            #{dates_subquery(range)}
          ), applicable_dates_subquery AS (
            #{applicable_dates_subquery}
          )
          #{self.select('DISTINCT(time_tables.id)').joins("INNER JOIN applicable_dates_subquery ON applicable_dates_subquery.time_table_id = time_tables.id").to_sql}
        SQL

        ids += ::ActiveRecord::Base.connection.execute(query).map{|r| r['id']}
      end
      ids.to_a
    end

    def self.dates_subquery(date_range)
      <<-SQL
      select CURRENT_DATE + i AS date
      from generate_series(#{(date_range.min - Time.now.to_date).to_i}, #{(date_range.max - Time.now.to_date).to_i}) i
      SQL
    end

    def self.applicable_dates_subquery
      <<-SQL
      SELECT dates.date, time_tables.id AS time_table_id
      FROM dates
        LEFT JOIN  \"#{Apartment::Tenant.current}\".time_tables ON 1=1
        LEFT JOIN  \"#{Apartment::Tenant.current}\"."time_table_dates" AS excluded_dates ON excluded_dates."time_table_id" = "time_tables"."id" AND excluded_dates.date = dates.date AND excluded_dates.in_out = false
        LEFT JOIN  \"#{Apartment::Tenant.current}\"."time_table_dates" AS included_dates ON included_dates."time_table_id" = "time_tables"."id" AND included_dates.date = dates.date AND included_dates.in_out = true
        LEFT JOIN  \"#{Apartment::Tenant.current}\"."time_table_periods" AS periods ON periods."time_table_id" = "time_tables"."id" AND periods.period_start <= dates.date AND periods.period_end >= dates.date
      WHERE
        (included_dates.id IS NOT NULL OR (periods.id IS NOT NULL AND (time_tables.int_day_types & POW(2, ((DATE_PART('dow', dates.date)::int+6)%7)+2)::int) > 0) AND excluded_dates.id IS NULL)
      GROUP BY dates.date, time_tables.id
      ORDER BY dates.date ASC
      SQL
    end

    # THIS WILL NEED SOME LATER OPTIM
    def self.clean!
      # Delete vehicle_journey time_table association
      ::ActiveRecord::Base.transaction do
        time_table_ids = pluck(:id)
        Chouette::TimeTablesVehicleJourney.where(time_table_id: time_table_ids).delete_all
        Chouette::TimeTableDate.joins(:time_table).where(time_tables: {id: time_table_ids}).delete_all
        Chouette::TimeTablePeriod.joins(:time_table).where(time_tables: {id: time_table_ids}).delete_all

        delete_all
      end
    end

    def color
      _color = read_attribute(:color)
      _color.present? ? _color : nil
    end

    def find_date_by_id id
      self.dates.find id
    end

    def update_in_out date, in_out
      date.in_out = in_out
    end

    def find_period_by_id id
      self.periods.find(id)
    end

    def build_period
      self.periods.build
    end

    def delete_periods deleted_periods
      self.periods.delete(deleted_periods)
    end

    def self.state_permited_attributes item
      item.slice('comment', 'color').to_hash
    end

    def actualize
      self.dates.clear
      self.periods.clear
      from = self.calendar.convert_to_time_table
      self.dates   = from.dates
      self.periods = from.periods
      self.save
    end

    def save_shortcuts
      return if skip_save_shortcuts
      shortcuts_update
      return unless changes.key?(:start_date) || changes.key?(:end_date)

      self.update_columns start_date: start_date, end_date: end_date
    end

    # Update start_date/end_date of all TimeTables in the current scope
    def self.update_shortcuts
      current_scope = self.current_scope || all

      bouding_dates = current_scope.left_joins(:dates).left_joins(:periods).group('time_tables.id').select(
        'time_tables.id as id',
        'least(min(time_table_dates.date), min(time_table_periods.period_start)) as start_date',
        'greatest(max(time_table_dates.date), max(time_table_periods.period_end)) as end_date')

      update_query = <<-SQL
        WITH bounding_dates AS (#{bouding_dates.to_sql})
        UPDATE time_tables
        SET start_date = bounding_dates.start_date, end_date = bounding_dates.end_date
        FROM bounding_dates WHERE time_tables.id = bounding_dates.id
      SQL

      connection.execute update_query
    end

    # The period covered by the TimeTable (from the minimum to the maximum dates)
    def validity_period
      start_date..end_date if start_date && end_date
    end

    def shortcuts_update
      dates_array = bounding_dates

      if dates_array.empty?
        self.start_date=nil
        self.end_date=nil
      else
        self.start_date=dates_array.min
        self.end_date=dates_array.max
      end
    end

    def periods_max_date
      return nil if self.periods.empty?

      min_start = self.periods.map(&:period_start).compact.min
      max_end = self.periods.map(&:period_end).compact.max
      result = nil

      if max_end && min_start
        max_end.downto( min_start) do |date|
          if self.valid_days.include?(date.cwday) && !self.excluded_date?(date)
              result = date
              break
          end
        end
      end
      result
    end
    def periods_min_date
      return nil if self.periods.empty?

      min_start = self.periods.map(&:period_start).compact.min
      max_end = self.periods.map(&:period_end).compact.max
      result = nil

      if max_end && min_start
        min_start.upto(max_end) do |date|
          if self.valid_days.include?(date.cwday) && !self.excluded_date?(date)
              result = date
              break
          end
        end
      end
      result
    end

    def clone_periods
      periods = []
      self.periods.each { |p| periods << p.copy}
      periods.sort_by(&:period_start)
    end

    def build_date in_out, date
      self.dates.build in_out: in_out, date: date
    end

    def saved_dates
      Hash[self.dates.collect{ |d| [d.id, d.date]}]
    end

    def all_dates
      dates
    end

    alias_attribute :name, :comment

    def full_display_name
      [get_objectid.short_id, comment].join(' - ')
    end

    def display_name
      full_display_name.truncate(40)
    end

    # produce a copy of periods without anyone overlapping or including another
    def optimize_overlapping_periods
      periods = self.clone_periods
      optimized = []
      i=0
      while i < periods.length
        p1 = periods[i]
        optimized << p1
        j= i+1
        while j < periods.length
          p2 = periods[j]
          if p1.contains? p2
            periods.delete p2
          elsif p1.overlap? p2
            p1.period_start = [p1.period_start,p2.period_start].min
            p1.period_end = [p1.period_end,p2.period_end].max
            periods.delete p2
          else
            j += 1
          end
        end
        i+= 1
      end
      optimized.sort { |a,b| a.period_start <=> b.period_start}
    end

    def duplicate(tt_params = {})
      tt = self.deep_clone include: [:periods, :dates], except: [:object_version, :objectid]
      tt.created_from = self
      tt.comment      = tt_params[:comment].presence || I18n.t("activerecord.copy", :name => self.comment)
      tt
    end

    def intersect_periods!(mask_periods)
      apply to_timetable.limit(mask_periods).normalize!
    end

    def remove_periods!(removed_periods)
      deleted_dates = []
      dates.each do |date|
        if removed_periods.any? { |p| p.include? date.date }
           deleted_dates << date
        end
      end
      dates.delete deleted_dates

      deleted_periods = []
      periods.each do |period|
        modified_ranges = removed_periods.inject([period.range]) do |period_ranges, removed_period|
          period_ranges.map { |p| p.remove removed_period }.flatten
        end

        unless modified_ranges.empty?
          modified_ranges.each_with_index do |modified_range, index|
            if modified_range.min != modified_range.max
              new_period = index == 0 ? period : periods.build

              new_period.period_start, new_period.period_end =
                                       modified_range.min, modified_range.max
            else
              build_date_if_relevant modified_range.min
              deleted_periods << period if index == 0
            end
          end
        else
          deleted_periods << period
        end
      end
      periods.delete deleted_periods
    end

    def build_date_if_relevant date
      if applicable_date?(date) && !dates.any?{|d| d.date == date}
        dates.build in_out: true, date: date
      end
    end

    def empty?
      dates.empty? && periods.empty?
    end

    def to_timetable
      Cuckoo::Timetable.new.tap do |timetable|
        dates.each do |date|
          if date.in?
            timetable.included_dates << date.date
          else
            timetable.excluded_dates << date.date
          end
        end

        periods.each do |period|
          timetable.periods << period.to_timetable_period
        end
      end
    end

    def to_days_bit
      to_timetable.to_days_bit
    end

    def apply(timetable)
      Applier.new(self, timetable).apply
      self
    end

    class Applier

      attr_reader :time_table, :timetable

      def initialize(time_table, timetable)
        @time_table, @timetable = time_table, timetable
      end

      def apply
        apply_day_types
        apply_included_dates
        apply_excluded_dates
        apply_periods

        self
      end

      delegate :int_day_types=, :dates, :periods, to: :time_table

      def apply_day_types
        if (days_of_week = timetable.uniq_days_of_week)
          self.int_day_types = days_of_week.hash
        else
          raise ArgumentError
        end
      end

      def apply_included_dates
        included_dates = timetable.included_dates.to_a
        dates.select(&:in?).sort_by(&:date).each do |date|
          expected_date = included_dates.shift
          if expected_date
            date.date = expected_date
          else
            dates.delete date
          end
        end

        included_dates.each do |included_date|
          dates.build date: included_date, in_out: true
        end
      end

      def apply_excluded_dates
        excluded_dates = timetable.excluded_dates.to_a
        dates.select(&:out?).sort_by(&:date).each do |date|
          expected_date = excluded_dates.shift
          if expected_date
            date.date = expected_date
          else
            dates.delete date
          end
        end

        excluded_dates.each do |excluded_date|
          dates.build date: excluded_date, in_out: false
        end
      end

      def apply_periods
        expected_periods = timetable.periods.to_a
        periods.sort_by(&:period_start).each do |period|
          expected_period = expected_periods.shift
          if expected_period
            period.period_start = expected_period.first
            period.period_end = expected_period.last
          else
            periods.delete period
          end
        end

        expected_periods.each do |period|
          periods.build period_start: period.first, period_end: period.last
        end
      end

    end

  end
end
