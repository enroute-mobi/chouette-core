module Chouette
  class TimeTable < Chouette::TridentActiveRecord
    has_metadata
    include ChecksumSupport
    include TimeTableRestrictions
    include ObjectidSupport
    include ApplicationDaysSupport
    include TimetableSupport

    acts_as_taggable

    attr_accessor :tag_search, :skip_save_shortcuts

    def self.ransackable_attributes auth_object = nil
      (column_names + ['tag_search']) + _ransackers.keys
    end

    ransacker :unaccented_comment, formatter: ->(val){ val.parameterize } do
      Arel.sql('unaccent(time_tables.comment)')
    end

    has_and_belongs_to_many :vehicle_journeys, :class_name => 'Chouette::VehicleJourney'
    has_many :routes, -> { distinct }, through: :vehicle_journeys, :class_name => 'Chouette::Route'
    has_many :lines, -> { distinct }, through: :routes, :class_name => 'Chouette::Line'

    has_many :dates, -> {order(:date)}, inverse_of: :time_table, :validate => :true, :class_name => "Chouette::TimeTableDate", dependent: :destroy
    has_many :periods, -> {order(:period_start)}, inverse_of: :time_table, :validate => :true, :class_name => "Chouette::TimeTablePeriod", dependent: :destroy

    belongs_to :calendar
    belongs_to :created_from, class_name: 'Chouette::TimeTable'

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

    scope :non_empty, -> { where.not(id: empty) }

    scope :linked_to_lines, ->(lines) { joins(vehicle_journeys: :route).where('routes.line_id' => lines.map(&:id)) }
    scope :by_text, ->(text) { text.blank? ? all : where('unaccent(time_tables.comment) ILIKE :t or lower(time_tables.objectid) LIKE :t', t: "%#{text.downcase}%") }

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

    def self.object_id_key
      "Timetable"
    end

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

    def continuous_dates
      in_days = self.dates.where(in_out: true).sort_by(&:date)
      chunk = {}
      group = nil
      in_days.each_with_index do |date, index|
        group ||= index
        group = (date.date == in_days[index - 1].date + 1.day) ? group : group + 1
        chunk[group] ||= []
        chunk[group] << date
      end
      # Remove less than 2 continuous day chunk
      chunk.values.delete_if {|dates| dates.count < 2}
    end

    def color
      _color = read_attribute(:color)
      _color.present? ? _color : nil
    end

    def convert_continuous_dates_to_periods
      chunks = self.continuous_dates

      transaction do
        chunks.each do |chunk|
          self.periods.create!(period_start: chunk.first.date, period_end: chunk.last.date)
          self.dates.delete(chunk)
        end
      end
    end

    def find_date_by_id id
      self.dates.find id
    end

    def destroy_date date
      date.destroy
    end

    def update_in_out date, in_out
      if in_out != date.in_out
        date.update_attributes({in_out: in_out})
      end
    end

    def find_period_by_id id
      self.periods.where(id: id).last
    end

    def build_period
      periods.build
    end

    def destroy_period period
      period.destroy
    end

    def self.state_permited_attributes item
      item.slice('comment', 'color').to_hash
    end

    def self.start_validity_period
      [Chouette::TimeTable.minimum(:start_date)].compact.min
    end
    def self.end_validity_period
      [Chouette::TimeTable.maximum(:end_date)].compact.max
    end

    def add_exclude_date(in_out, date)
      self.dates.create!({in_out: in_out, date: date})
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

    def validity_out_from_on?(expected_date)
      return false unless self.end_date
      self.end_date <= expected_date
    end

    def validity_out_between?(starting_date, ending_date)
      return false unless self.start_date
      starting_date < self.end_date  &&
        self.end_date <= ending_date
    end
    def self.validity_out_from_on?(expected_date,limit=0)
      if limit==0
        Chouette::TimeTable.where("end_date <= ?", expected_date)
      else
        Chouette::TimeTable.where("end_date <= ?", expected_date).limit( limit)
      end
    end
    def self.validity_out_between?(start_date, end_date,limit=0)
      if limit==0
        Chouette::TimeTable.where( "? < end_date", start_date).where( "end_date <= ?", end_date)
      else
        Chouette::TimeTable.where( "? < end_date", start_date).where( "end_date <= ?", end_date).limit( limit)
      end
    end

    # Return days which intersects with the time table dates and periods
    def intersects(days)
      [].tap do |intersect_days|
        days.each do |day|
          intersect_days << day if include_day?(day)
        end
      end
    end

    def include_day?(day)
      include_in_dates?(day) || include_in_periods?(day)
    end

    def include_in_dates?(day)
      self.dates.any?{ |d| d.date === day && d.in_out == true }
    end

    def excluded_date?(day)
      self.dates.any?{ |d| d.date === day && d.in_out == false }
    end

    def include_in_periods?(day)
      self.periods.any?{ |period| period.period_start <= day &&
                                  day <= period.period_end &&
                                  valid_days.include?(day.cwday) &&
                                  ! excluded_date?(day) }
    end

    def include_in_overlap_dates?(day)
      return false if self.excluded_date?(day)

      counter = self.dates.select{ |d| d.date === day}.size + self.periods.select{ |period| period.period_start <= day && day <= period.period_end && valid_days.include?(day.cwday) }.size
      counter <= 1 ? false : true
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
    def bounding_dates
      bounding_min = self.dates.select{|d| d.in_out}.map(&:date).compact.min
      bounding_max = self.dates.select{|d| d.in_out}.map(&:date).compact.max

      unless self.periods.empty?
        bounding_min = periods_min_date if periods_min_date &&
            (bounding_min.nil? || (periods_min_date < bounding_min))

        bounding_max = periods_max_date if periods_max_date &&
            (bounding_max.nil? || (bounding_max < periods_max_date))
      end
      [bounding_min, bounding_max].compact
    end

    def date_range
      bounding_min, bounding_max = bounding_dates
      if bounding_min && bounding_max
        Range.new(bounding_min, bounding_max)
      end
    end

    def effective_days_of_period(period,valid_days=self.valid_days)
      days = []
        period.period_start.upto(period.period_end) do |date|
          if valid_days.include?(date.cwday) && !self.excluded_date?(date)
              days << date
          end
        end
      days
    end

    def effective_days(valid_days=self.valid_days)
      days=self.effective_days_of_periods(valid_days)
      self.dates.each do |d|
        days |= [d.date] if d.in_out
      end
      days.sort
    end

    def effective_days_of_periods(valid_days=self.valid_days)
      days = []
      self.periods.each { |p| days |= self.effective_days_of_period(p,valid_days)}
      days.sort
    end

    def clone_periods
      periods = []
      self.periods.each { |p| periods << p.copy}
      periods.sort_by(&:period_start)
    end

    def included_days
      days = []
      self.dates.each do |d|
        days |= [d.date] if d.in_out
      end
      days.sort
    end

    def excluded_days
      days = []
      self.dates.each do |d|
        days |= [d.date] unless d.in_out
      end
      days.sort
    end

    def create_date in_out:, date:
      self.dates.create in_out: in_out, date: date
    end

    def saved_dates
      Hash[self.dates.collect{ |d| [d.id, d.date]}]
    end

    def all_dates
      dates
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

    # add a peculiar day or switch it from excluded to included
    def add_included_day(d)
      if self.excluded_date?(d)
        self.dates.each do |date|
          if date.date === d
            date.in_out = true
          end
        end
      elsif !self.include_in_dates?(d)
        self.dates << Chouette::TimeTableDate.new(:date => d, :in_out => true)
      end
    end

    # merge effective days from another timetable
    def merge!(another_tt)
      transaction do
        days = [].tap do |array|
          array.push(*self.effective_days, *another_tt.effective_days)
          array.uniq!
        end

        self.dates.clear
        self.periods.clear

        days.each do |day|
          self.dates << Chouette::TimeTableDate.new(date: day, in_out: true)
        end
        self.save!
      end
      self.convert_continuous_dates_to_periods
    end

    def included_days_in_dates_and_periods
      in_day  = self.dates.select {|d| d.in_out }.map(&:date)
      out_day = self.dates.select {|d| !d.in_out }.map(&:date)

      in_periods = self.periods.map{|p| (p.period_start..p.period_end).to_a }.flatten
      days = in_periods + in_day
      days -= out_day
      days
    end

    # keep common dates with another_tt
    def intersect!(another_tt)
      transaction do
        days = [].tap do |array|
          array.push(*self.effective_days)
          array.delete_if {|day| !another_tt.effective_days.include?(day) }
          array.uniq!
        end

        self.dates.clear
        self.periods.clear

        days.sort.each do |d|
          self.dates << Chouette::TimeTableDate.new(:date => d, :in_out => true)
        end
        self.save!
      end
      self.convert_continuous_dates_to_periods
    end

    # remove common dates with another_tt
    def disjoin!(another_tt)
      transaction do
        days = [].tap do |array|
          array.push(*self.effective_days)
          array.delete_if {|day| another_tt.effective_days.include?(day) }
          array.uniq!
        end

        self.dates.clear
        self.periods.clear

        days.sort.each do |d|
          self.dates << Chouette::TimeTableDate.new(:date => d, :in_out => true)
        end
        self.save!
      end
      self.convert_continuous_dates_to_periods
    end

    def duplicate(tt_params = {})
      tt = self.deep_clone include: [:periods, :dates], except: [:object_version, :objectid]
      tt.tag_list.add(*self.tag_list) unless self.tag_list.empty?
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
      Timetable.new.tap do |timetable|
        dates.each do |date|
          if date.in?
            timetable.included_dates << date.date
          else
            timetable.excluded_dates << date.date
          end
        end

        periods.each do |period|
          timetable.periods << Timetable::Period.new(period.period_start, period.period_end, days_of_week)
        end
      end
    end

    def apply(timetable)
      Applier.new(self, timetable).apply
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
