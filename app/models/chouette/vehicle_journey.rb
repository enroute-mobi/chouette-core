# frozen_string_literal: true

module Chouette
  class VehicleJourney < Referential::Model
    include CustomFieldsSupport
    include TransportModeEnumerations

    has_metadata

    attr_reader :time_table_tokens

    def self.nullable_attributes
      [:transport_mode, :published_journey_name, :published_journey_identifier]
    end

    belongs_to :company, optional: true # CHOUETTE-3247 failing specs
    belongs_to :accessibility_assessment, class_name: '::AccessibilityAssessment', optional: true # CHOUETTE-3247 optional: true
    belongs_to :company_light, -> {select(:id, :objectid, :line_referential_id)}, class_name: "Chouette::Company", foreign_key: :company_id, optional: true # CHOUETTE-3247 failing specs
    belongs_to :route # CHOUETTE-3247 failing specs
    belongs_to :journey_pattern # CHOUETTE-3247 failing specs
    has_array_of :service_facility_sets, class_name: '::ServiceFacilitySet'

    has_many :stop_areas, through: :journey_pattern

    has_array_of :line_notices, class_name: 'Chouette::LineNotice'
    belongs_to_public :line_notices,
      index_collection: -> { Chouette::VehicleJourney.where.not('line_notice_ids = ARRAY[]::bigint[]') }

    delegate :line, to: :route, allow_nil: true

    has_and_belongs_to_many :footnotes, :class_name => 'Chouette::Footnote'

    with_options(if: -> { validation_context != :inserter }) do |except_in_inserter_context|
      except_in_inserter_context.validates :route, presence: true
      except_in_inserter_context.validates :journey_pattern, presence: true
      except_in_inserter_context.before_validation :calculate_vehicle_journey_at_stop_day_offset
    end
    validate :validate_passing_times_chronology

    has_many :vehicle_journey_at_stops, -> { includes(:stop_point).order("stop_points.position") }, inverse_of: :vehicle_journey, dependent: :destroy
    has_and_belongs_to_many :time_tables, :class_name => 'Chouette::TimeTable', :foreign_key => "vehicle_journey_id", :association_foreign_key => "time_table_id"
    has_many :stop_points, -> { order("stop_points.position") }, :through => :vehicle_journey_at_stops
    has_many :vehicle_journey_time_table_relationships, class_name: 'Chouette::TimeTablesVehicleJourney'

    scope :with_companies, -> (companies) { joins(route: :line).where(lines: { company_id: companies }) }

    scope :with_stop_area_ids, ->(ids){
      _ids = ids.select(&:present?).map(&:to_i)
      if _ids.present?
        where("array(SELECT stop_points.stop_area_id::integer FROM stop_points INNER JOIN journey_patterns_stop_points ON journey_patterns_stop_points.stop_point_id = stop_points.id WHERE journey_patterns_stop_points.journey_pattern_id = vehicle_journeys.journey_pattern_id) @> array[?]", _ids)
      else
        all
      end
    }

    scope :with_stop_area_id, ->(id){
      if id.present?
        joins(journey_pattern: :stop_points).where('stop_points.stop_area_id = ?', id)
      else
        all
      end
    }

    scope :with_ordered_stop_area_ids, ->(first, second){
      if first.present? && second.present?
        joins(journey_pattern: :stop_points).
          joins('INNER JOIN "journey_patterns" ON "journey_patterns"."id" = "vehicle_journeys"."journey_pattern_id" INNER JOIN "journey_patterns_stop_points" ON "journey_patterns_stop_points"."journey_pattern_id" = "journey_patterns"."id" INNER JOIN "stop_points" as "second_stop_points" ON "second_stop_points"."id" = "journey_patterns_stop_points"."stop_point_id"').
          where('stop_points.stop_area_id = ?', first).
          where('second_stop_points.stop_area_id = ? and stop_points.position < second_stop_points.position', second)
      else
        all
      end
    }

    scope :starting_with, ->(id){
      if id.present?
        joins(journey_pattern: :stop_points).where('stop_points.position = 0 AND stop_points.stop_area_id = ?', id)
      else
        all
      end
    }

    scope :ending_with, ->(id){
      if id.present?
        pattern_ids = all.select(:journey_pattern_id).distinct.map(&:journey_pattern_id)
        pattern_ids = Chouette::JourneyPattern.where(id: pattern_ids).to_a.select{|jp| p "ici: #{jp.stop_points.order(:position).last.stop_area_id}" ; jp.stop_points.order(:position).last.stop_area_id == id.to_i}.map &:id
        where(journey_pattern_id: pattern_ids)
      else
        all
      end
    }

    scope :order_by_departure_time, -> (dir) {
      field = "MIN(current_date + departure_day_offset * interval '24 hours' + departure_time)"
      joins(:vehicle_journey_at_stops)
      .select('id', field)
      .group(:id)
      .order(Arel.sql("#{field} #{dir}"))
    }

    scope :order_by_arrival_time, -> (dir) {
      field = "MAX(current_date + arrival_day_offset * interval '24 hours' + arrival_time)"
      joins(:vehicle_journey_at_stops)
      .select('id', field)
      .group(:id)
      .order(Arel.sql("#{field} #{dir}"))
    }

    def self.with_departure_arrival_second_offsets
      stops = Chouette::VehicleJourneyAtStop.joins(:stop_point).where('vehicle_journey_id = vehicle_journeys.id')

      query = joins("JOIN LATERAL (#{stops.order('stop_points.position').limit(1).select(:departure_time, :departure_day_offset).to_sql}) first_stop ON true")
              .joins("JOIN LATERAL (#{stops.order('stop_points.position': :desc).select(:arrival_time, :arrival_day_offset).limit(1).to_sql}) last_stop ON true")
              .select('*',
                      'EXTRACT(EPOCH FROM first_stop.departure_time) + first_stop.departure_day_offset * 86400 as departure_second_offset',
                      'EXTRACT(EPOCH FROM last_stop.arrival_time) + last_stop.arrival_day_offset * 86400 as arrival_second_offset')

      from(query, :vehicle_journeys)
    end

    scope :without_any_time_table, -> { joins('LEFT JOIN time_tables_vehicle_journeys ON time_tables_vehicle_journeys.vehicle_journey_id = vehicle_journeys.id LEFT JOIN time_tables ON time_tables.id = time_tables_vehicle_journeys.time_table_id').where(:time_tables => { :id => nil}) }
    scope :without_any_passing_time, -> { joins('LEFT JOIN vehicle_journey_at_stops ON vehicle_journey_at_stops.vehicle_journey_id = vehicle_journeys.id').where(vehicle_journey_at_stops: { id: nil }) }
    scope :scheduled, ->(time_tables) { joins(:time_tables).merge(time_tables).distinct }
    scope :with_lines, -> (lines) { joins(:route).where(routes: { line_id: lines }) }

    scope :with_time_tables, -> (time_tables) { joins(:time_tables).where(time_tables: { id: time_tables }) }

    scope :by_text, ->(text) { text.blank? ? all : where('lower(vehicle_journeys.published_journey_name) LIKE :t or lower(vehicle_journeys.objectid) LIKE :t', t: "%#{text.downcase}%") }

    # We need this for the ransack object in the filters
    ransacker :stop_area_ids

    # returns VehicleJourneys with at least 1 day in their time_tables
    # included in the given range
    def self.with_matching_timetable date_range
      scope = Chouette::TimeTable.joins(
        :vehicle_journeys
      ).merge(self.all)
      dates_scope = scope.joins(:dates).select('time_table_dates.date').order('time_table_dates.date').where('time_table_dates.in_out' => true)
      min_date = scope.joins(:periods).select('time_table_periods.period_start').order('time_table_periods.period_start').first&.period_start
      min_date = [min_date, dates_scope.first&.date].compact.min
      max_date = scope.joins(:periods).select('time_table_periods.period_end').order('time_table_periods.period_end').last&.period_end
      max_date = [max_date, dates_scope.last&.date].compact.max

      return none unless min_date && max_date

      date_range = date_range & (min_date..max_date)

      return none unless date_range && date_range.count > 0

      time_table_ids = scope.overlapping(date_range).applied_at_least_once_in_ids(date_range)
      joins(:time_tables).where("time_tables.id" => time_table_ids).distinct
    end

    def self.scheduled_on(date)
      joins(:time_tables).merge(Chouette::TimeTable.scheduled_on(date)).distinct
    end

    # Returns ordered arrival/departure time of days for all Vehicle Journey stops
    def passing_times
      vehicle_journey_at_stops.flat_map do |vehicle_journey_at_stop|
        %w{arrival departure}.map do |part|
          vehicle_journey_at_stop.send "#{part}_time_of_day"
        end
      end
    end

    def validate_passing_times_chronology
      passing_times.each_cons(2) do |previous_time_of_day, time_of_day|
        if time_of_day.present? && previous_time_of_day.present? && time_of_day < previous_time_of_day
          # For the moment, a single/global error is defined
          errors.add :vehicle_journey_at_stops, :invalid_chronology
          return false
        end
      end

      true
    end

    def local_id
      "local-#{self.referential.id}-#{self.route.line.get_objectid.local_id}-#{self.id}"
    end

    def checksum_attributes(db_lookup = true)
      [].tap do |attrs|
        attrs << self.published_journey_name
        attrs << self.published_journey_identifier
        loaded_company = association(:company).loaded? ? company : company_light
        attrs << loaded_company.try(:get_objectid).try(:local_id)
        footnotes = self.footnotes
        footnotes += Footnote.for_vehicle_journey(self) if db_lookup && !self.new_record?
        attrs << footnotes.uniq.map(&:checksum).sort
        attrs << line_notices.uniq.map(&:objectid).sort
        vjas =  self.vehicle_journey_at_stops
        vjas += VehicleJourneyAtStop.where(vehicle_journey_id: self.id) if db_lookup && !self.new_record?
        attrs << vjas.uniq.sort_by { |s| s.stop_point&.position }.map(&:checksum)
        attrs << service_facility_set_ids
        attrs << accessibility_assessment_id
      end
    end

    has_checksum_children VehicleJourneyAtStop
    has_checksum_children Footnote
    has_checksum_children Chouette::LineNotice
    has_checksum_children StopPoint

    def calculate_vehicle_journey_at_stop_day_offset
      Chouette::VehicleJourneyAtStopsDayOffset.new(
        vehicle_journey_at_stops.sort_by{ |vjas| vjas.stop_point.position }
      ).calculate!
    end

    accepts_nested_attributes_for :vehicle_journey_at_stops, :allow_destroy => true

    def vehicle_journey_at_stops_matrix
      at_stops = self.vehicle_journey_at_stops.to_a.dup
      active_stop_point_ids = journey_pattern.stop_points.map(&:id)

      (route.stop_points.map(&:id) - at_stops.map(&:stop_point_id)).each do |id|
        vjas = Chouette::VehicleJourneyAtStop.new(stop_point_id: id)
        vjas.dummy = !active_stop_point_ids.include?(id)
        at_stops.insert(route.stop_points.map(&:id).index(id), vjas)
      end
      at_stops
    end

    def create_or_find_vjas_from_state vjas
      return vehicle_journey_at_stops.find(vjas['id']) if vjas['id']
      stop_point = Chouette::StopPoint.find_by(objectid: vjas['stop_point_objectid'])
      stop       = vehicle_journey_at_stops.create(stop_point: stop_point)
      vjas['id'] = stop.id
      vjas['new_record'] = true
      stop
    end

    def update_vjas_from_state state
      state.each do |vjas|
        next if vjas["dummy"]
        stop_point = Chouette::StopPoint.find_by(objectid: vjas['stop_point_objectid'])
        stop_area = stop_point&.stop_area
        tz = stop_area&.time_zone
        tz = tz && ActiveSupport::TimeZone[tz]
        utc_offset = tz ? tz.utc_offset : 0

        params = {}

        %w{departure arrival}.each do |part|
          field = "#{part}_time"
          time_of_day = TimeOfDay.new vjas[field]['hour'], vjas[field]['minute'], utc_offset: utc_offset
          params["#{part}_time_of_day".to_sym] = time_of_day
        end
        params[:stop_area_id] = vjas['specific_stop_area_id']
        stop = create_or_find_vjas_from_state(vjas)
        stop.update(params)
        vjas.delete('errors')
        vjas['errors'] = stop.errors if stop.errors.any?
      end
    end

    def manage_referential_codes_from_state state
      # Delete removed referential_codes
      referential_codes = state["referential_codes"] || []
      defined_codes = referential_codes.map{ |c| c["id"] }
      codes.where.not(id: defined_codes).delete_all

      # Update or create other codes
      referential_codes.each do |code_item|
        ref_code = code_item["id"].present? ? codes.find(code_item["id"]) : codes.build
        ref_code.update({
          code_space_id: code_item["code_space_id"],
          value: code_item["value"]
        })
      end
    end

    def update_has_and_belongs_to_many_from_state item
      ['time_tables', 'footnotes', 'line_notices'].each do |assos|
        next unless item[assos]

        saved = self.send(assos).map(&:id)

        (saved - item[assos].map{|t| t['id']}).each do |id|
          self.send(assos).delete(self.send(assos).find(id))
        end

        item[assos].each do |t|
          klass = "Chouette::#{assos.classify}".constantize
          unless saved.include?(t['id'])
            self.send(assos) << klass.find(t['id'])
          end
        end
      end
    end

    def self.state_update route, state
      objects = []
      transaction do
        state.each do |item|
          item.delete('errors')
          vj = find_by(objectid: item['objectid']) || state_create_instance(route, item)
          next if item['deletable'] && vj.persisted? && vj.destroy
          objects << vj

          vj.update_vjas_from_state(item['vehicle_journey_at_stops'])
          vj.update(state_permited_attributes(item))
          vj.update_has_and_belongs_to_many_from_state(item)
          vj.manage_referential_codes_from_state(item)
          vj.update_checksum!
          item['errors']   = vj.errors.full_messages.uniq if vj.errors.any?
          item['checksum'] = vj.checksum
        end

        # Delete ids of new object from state if we had to rollback
        if state.any? {|item| item['errors']}
          state.map do |item|
            item.delete('objectid') if item['new_record']
            item['vehicle_journey_at_stops'].map {|vjas| vjas.delete('id') if vjas['new_record'] }
          end
          raise ::ActiveRecord::Rollback
        end
      end

      # Remove new_record flag && deleted item from state if transaction has been saved
      state.map do |item|
        item.delete('new_record')
        item['vehicle_journey_at_stops'].map {|vjas| vjas.delete('new_record') }
      end
      state.delete_if {|item| item['deletable']}
      objects
    end

    def self.state_create_instance route, item
      # Flag new record, so we can unset object_id if transaction rollback
      vj = route.vehicle_journeys.create(state_permited_attributes(item))
      vj.after_commit_objectid
      item['objectid'] = vj.objectid
      item['short_id'] = vj.get_objectid.short_id
      item['new_record'] = true
      vj
    end

    def self.state_permited_attributes item
      attrs = item.slice(
        'published_journey_identifier',
        'published_journey_name',
        'journey_pattern_id',
        'company_id',
        'accessibility_assessment_id'
      ).to_hash

      if item['journey_pattern']
        attrs['journey_pattern_id'] = item['journey_pattern']['id']
      end

      attrs['company_id'] = item['company'] ? item['company']['id'] : nil

      attrs['accessibility_assessment_id'] = item['accessibility_assessment'] ? item['accessibility_assessment']['id'] : nil

      attrs["custom_field_values"] = Hash[
        *(item["custom_fields"] || {})
          .map { |k, v| [k, v["value"]] }
          .flatten
      ]
      attrs
    end

    def time_table_tokens=(ids)
      self.time_table_ids = ids.split(",")
    end

    def bounding_dates
      dates = []

      time_tables.each do |tm|
        dates << tm.start_date if tm.start_date
        dates << tm.end_date if tm.end_date
      end

      dates.empty? ? [] : [dates.min, dates.max]
    end

    def self.matrix(vehicle_journeys)
      Hash[*VehicleJourneyAtStop.where(vehicle_journey_id: vehicle_journeys.pluck(:id)).map do |vjas|
        [ "#{vjas.vehicle_journey_id}-#{vjas.stop_point_id}", vjas]
      end.flatten]
    end

    def self.with_stops
      self
        .joins(:journey_pattern)
        .joins('
          LEFT JOIN "vehicle_journey_at_stops"
            ON "vehicle_journey_at_stops"."vehicle_journey_id" =
              "vehicle_journeys"."id"
            AND "vehicle_journey_at_stops"."stop_point_id" =
              "journey_patterns"."departure_stop_point_id"
        ')
        .order(Arel.sql('"vehicle_journey_at_stops"."departure_time"'))
    end

    # Requires a SELECT DISTINCT and a join with
    # "vehicle_journey_at_stops".
    #
    # Example:
    #   .select('DISTINCT "vehicle_journeys".*')
    #   .joins('
    #     LEFT JOIN "vehicle_journey_at_stops"
    #       ON "vehicle_journey_at_stops"."vehicle_journey_id" =
    #         "vehicle_journeys"."id"
    #   ')
    #   .where_departure_time_between('08:00', '09:45')
    def self.where_departure_time_between(
      start_time,
      end_time,
      allow_empty: false
    )
      self
        .where(
          %Q(
            "vehicle_journey_at_stops"."departure_time" >= ?
            AND "vehicle_journey_at_stops"."departure_time" <= ?
            #{
              if allow_empty
                'OR "vehicle_journey_at_stops"."id" IS NULL'
              end
            }
          ),
          "2000-01-01 #{start_time}:00 UTC",
          "2000-01-01 #{end_time}:00 UTC"
        )
    end

    def self.without_time_tables
      # Joins the VehicleJourney–TimeTable through table to select only those
      # VehicleJourneys that don't have an associated TimeTable.
      self
        .joins('
          LEFT JOIN "time_tables_vehicle_journeys"
            ON "time_tables_vehicle_journeys"."vehicle_journey_id" =
              "vehicle_journeys"."id"
        ')
        .where('"time_tables_vehicle_journeys"."vehicle_journey_id" IS NULL')
    end

    def trim_period period
      return unless period
      period.period_start = period.range.find{|date| Chouette::TimeTable.day_by_mask period.int_day_types, Chouette::TimeTable::RUBY_WEEKDAYS[date.wday] }
      period.period_end = period.range.reverse_each.find{|date| Chouette::TimeTable.day_by_mask period.int_day_types, Chouette::TimeTable::RUBY_WEEKDAYS[date.wday] }
      period
    end

    def merge_flattened_periods periods
      return [trim_period(periods.last)].compact unless periods.size > 1

      merged = []
      current = periods[0]
      any_day_matching = Proc.new {|period|
        period.range.any? do |date|
          Chouette::TimeTable.day_by_mask period.int_day_types, Chouette::TimeTable::RUBY_WEEKDAYS[date.wday]
        end
      }
      periods[1..-1].each do |period|
        if period.int_day_types == current.int_day_types \
          && (period.period_start - 1.day) <= current.period_end

          current.period_end = period.period_end if period.period_end > current.period_end
        else
          if any_day_matching.call(current)
            merged << trim_period(current)
          end

          current = period
        end
      end
      if any_day_matching.call(current)
        merged << trim_period(current)
      end
      merged
    end

    # Don't use for massive operations. Not optimized !
    def flattened_circulation_periods
      periods = time_tables.map(&:periods).flatten
      out = []
      dates = periods.map {|p| [p.period_start, p.period_end + 1.day]}

      included_dates = Hash[*time_tables.map do |t|
                              t.dates.select(&:in?).map {|d|
                                int_day_types = t.int_day_types
                                int_day_types = int_day_types | 2**(d.date.days_to_week_start + 2)
                                [d.date, int_day_types]
                              }
                            end.flatten]

      excluded_dates = Hash.new { |hash, key| hash[key] = [] }
      time_tables.each do |t|
        t.dates.select(&:out?).each {|d| excluded_dates[d.date] += t.periods.to_a }
      end

      (included_dates.keys + excluded_dates.keys).uniq.each do |d|
        dates << d
        dates << d + 1.day
      end

      dates = dates.flatten.uniq.sort
      dates.each_cons(2) do |from, to|
        to = to - 1.day
        if from == to
          matching = periods.select{|p| p.range.include?(from) }
        else
          # Find the elements that are both in a and b
          matching = periods.select{|p| (from..to) & p.range }
        end
        # Remove the portential excluded service date from the returned matching periods / dates
        matching -= excluded_dates[from] || []
        date_matching = included_dates[from]
        if matching.any? || date_matching
          int_day_types = 0
          matching.each {|p| int_day_types = int_day_types | p.time_table.int_day_types}
          int_day_types = int_day_types | date_matching if date_matching
          out << FlattennedCirculationPeriod.new(from, to, int_day_types)
        end
      end

      merge_flattened_periods out
    end
    alias operating_periods flattened_circulation_periods

    class FlattennedCirculationPeriod
      include ApplicationDaysSupport

      attr_accessor :period_start, :period_end, :int_day_types

      def initialize _start, _end, _days=nil
        @period_start = _start
        @period_end = _end
        @int_day_types = _days
      end

      def range
        (period_start..period_end)
      end

      def weekdays
        ([0]*7).tap{|days| valid_days.each do |v| days[v - 1] = 1 end}.join(',')
      end

      def <=> period
        period_start <=> period.period_start
      end

      def ==(other)
        other.respond_to?(:range) && other.respond_to?(:int_day_types) &&
          range == other.range && int_day_types == other.int_day_types
      end

      def hash
        [ range, int_day_types ].hash
      end
    end

    def self.clean!
      current_scope = self.current_scope || all

      return 0 unless current_scope.present?
      # There are several "DELETE CASCADE" in the schema like:
      #
      # TABLE "vehicle_journey_at_stops" CONSTRAINT "vjas_vj_fkey" FOREIGN KEY (vehicle_journey_id) REFERENCES vehicle_journeys(id) ON DELETE CASCADE
      # TABLE "time_tables_vehicle_journeys" CONSTRAINT "vjtm_vj_fkey" FOREIGN KEY (vehicle_journey_id) REFERENCES vehicle_journeys(id) ON DELETE CASCADE
      #
      # The ruby code makes the expected deletions
      # and the delete cascade will be the fallback

      Chouette::VehicleJourneyAtStop.where(vehicle_journey: current_scope).delete_all
      ReferentialCode.where(resource: current_scope).delete_all

      reflections.values.select do |r|
        r.is_a?(::ActiveRecord::Reflection::HasAndBelongsToManyReflection)
      end.each do |reflection|
        sql = %[
          DELETE FROM #{reflection.join_table}
          WHERE #{reflection.foreign_key} IN (#{current_scope.select(:id).to_sql});
        ]
        connection.execute sql
      end

      delete_all
    end

  end
end
