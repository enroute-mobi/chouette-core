# coding: utf-8
module Chouette
  class VehicleJourney < Chouette::TridentActiveRecord
    has_metadata
    include ChecksumSupport
    include CustomFieldsSupport
    include ObjectidSupport
    include TransportModeEnumerations

    enum journey_category: { timed: 0, frequency: 1 }

    # default_scope { where(journey_category: journey_categories[:timed]) }

    attr_reader :time_table_tokens

    def self.nullable_attributes
      [:transport_mode, :published_journey_name, :vehicle_type_identifier, :published_journey_identifier, :comment]
    end

    belongs_to :company
    belongs_to :company_light, -> {select(:id, :objectid, :line_referential_id)}, class_name: "Chouette::Company", foreign_key: :company_id
    belongs_to :route
    belongs_to :journey_pattern
    belongs_to :journey_pattern_only_objectid, -> {select("journey_patterns.id, journey_patterns.objectid")}, class_name: "Chouette::JourneyPattern", foreign_key: :journey_pattern_id
    has_many :stop_areas, through: :journey_pattern

    has_many :codes, class_name: 'ReferentialCode', as: :resource, dependent: :destroy

    belongs_to_public :stop_area_routing_constraints,
      collection_name: :ignored_stop_area_routing_constraints,
      index_collection: -> { Chouette::VehicleJourney.where.not('ignored_stop_area_routing_constraint_ids = ARRAY[]::bigint[]') }

    has_array_of :line_notices, class_name: 'Chouette::LineNotice'
    belongs_to_public :line_notices,
      index_collection: -> { Chouette::VehicleJourney.where.not('line_notice_ids = ARRAY[]::bigint[]') }

    delegate :line, to: :route, allow_nil: true

    has_and_belongs_to_many :footnotes, :class_name => 'Chouette::Footnote'
    has_array_of :ignored_routing_contraint_zones, class_name: 'Chouette::RoutingConstraintZone'
    has_array_of :ignored_stop_area_routing_constraints, class_name: 'StopAreaRoutingConstraint'

    validates_presence_of :route
    validates_presence_of :journey_pattern
    # validates :vehicle_journey_at_stops,
      # Validation temporarily removed for day offsets
      # :vjas_departure_time_must_be_before_next_stop_arrival_time,

      # vehicle_journey_at_stops_are_in_increasing_time_order: false
    validates_presence_of :number

    has_many :vehicle_journey_at_stops, -> { includes(:stop_point).order("stop_points.position") }, dependent: :destroy
    has_and_belongs_to_many :time_tables, :class_name => 'Chouette::TimeTable', :foreign_key => "vehicle_journey_id", :association_foreign_key => "time_table_id"
    has_many :stop_points, -> { order("stop_points.position") }, :through => :vehicle_journey_at_stops

    before_validation :set_default_values,
      :calculate_vehicle_journey_at_stop_day_offset

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

    scope :without_any_time_table, -> { joins('LEFT JOIN time_tables_vehicle_journeys ON time_tables_vehicle_journeys.vehicle_journey_id = vehicle_journeys.id LEFT JOIN time_tables ON time_tables.id = time_tables_vehicle_journeys.time_table_id').where(:time_tables => { :id => nil}) }
    scope :without_any_passing_time, -> { joins('LEFT JOIN vehicle_journey_at_stops ON vehicle_journey_at_stops.vehicle_journey_id = vehicle_journeys.id').where(vehicle_journey_at_stops: { id: nil }) }
    scope :scheduled, -> { joins(:time_tables).merge(Chouette::TimeTable.non_empty) }
    scope :with_lines, -> (lines) { joins(:route).where(routes: { line_id: lines }) }

    scope :by_text, ->(text) { text.blank? ? all : where('lower(vehicle_journeys.published_journey_name) LIKE :t or lower(vehicle_journeys.objectid) LIKE :t', t: "%#{text.downcase}%") }

    scope :by_code, ->(code_space, value) { joins(codes: :code_space).where("referential_codes.code_space_id = ? AND value = ?", code_space, value) }

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

    # TODO: Remove this validator
    # We've eliminated this validation because it prevented vehicle journeys
    # from being saved with at-stops having a day offset greater than 0,
    # because these would have times that were "earlier" than the previous
    # at-stop. TBD by Luc whether we're deleting this validation altogether or
    # instead rejiggering it to work with day offsets.
    def vjas_departure_time_must_be_before_next_stop_arrival_time
      notice = 'departure time must be before next stop arrival time'
      vehicle_journey_at_stops.each_with_index do |current_stop, index|
        next_stop = vehicle_journey_at_stops[index + 1]

        next unless next_stop && (next_stop[:arrival_time] < current_stop[:departure_time])

        current_stop.errors.add(:departure_time, notice)
        self.errors.add(:vehicle_journey_at_stops, notice)
      end
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

        # The double condition prevents a SQL query "WHERE 1=0"
        if ignored_routing_contraint_zone_ids.present? && ignored_routing_contraint_zones.present?
          attrs << ignored_routing_contraint_zones.map(&:checksum).sort
        end
        if ignored_stop_area_routing_constraint_ids.present? && ignored_stop_area_routing_constraints.present?
          attrs << ignored_stop_area_routing_constraints.map(&:checksum).sort
        end
      end
    end

    has_checksum_children VehicleJourneyAtStop
    has_checksum_children Footnote
    has_checksum_children Chouette::LineNotice
    has_checksum_children StopPoint

    def set_default_values
      if number.nil?
        self.number = 0
      end
    end

    def calculate_vehicle_journey_at_stop_day_offset
      Chouette::VehicleJourneyAtStopsDayOffset.new(
        vehicle_journey_at_stops.sort_by{ |vjas| vjas.stop_point.position }
      ).calculate!
    end

    accepts_nested_attributes_for :vehicle_journey_at_stops, :allow_destroy => true

    def presenter
      @presenter ||= ::VehicleJourneyPresenter.new( self)
    end

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
        stop.update_attributes(params)
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
        ref_code.update_attributes({
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
          vj.update_attributes(state_permited_attributes(item))
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
        'ignored_routing_contraint_zone_ids',
        'ignored_stop_area_routing_constraint_ids'
      ).to_hash

      if item['journey_pattern']
        attrs['journey_pattern_id'] = item['journey_pattern']['id']
      end

      attrs['company_id'] = item['company'] ? item['company']['id'] : nil

      attrs["custom_field_values"] = Hash[
        *(item["custom_fields"] || {})
          .map { |k, v| [k, v["value"]] }
          .flatten
      ]
      attrs
    end

    def missing_stops_in_relation_to_a_journey_pattern(selected_journey_pattern)
      selected_journey_pattern.stop_points - self.stop_points
    end
    def extra_stops_in_relation_to_a_journey_pattern(selected_journey_pattern)
      self.stop_points - selected_journey_pattern.stop_points
    end
    def extra_vjas_in_relation_to_a_journey_pattern(selected_journey_pattern)
      extra_stops = self.extra_stops_in_relation_to_a_journey_pattern(selected_journey_pattern)
      self.vehicle_journey_at_stops.select { |vjas| extra_stops.include?( vjas.stop_point)}
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

    def update_journey_pattern( selected_journey_pattern)
      return unless selected_journey_pattern.route_id==self.route_id

      missing_stops_in_relation_to_a_journey_pattern(selected_journey_pattern).each do |sp|
        self.vehicle_journey_at_stops.build( :stop_point => sp)
      end
      extra_vjas_in_relation_to_a_journey_pattern(selected_journey_pattern).each do |vjas|
        vjas._destroy = true
      end
    end

    def fill_passing_times!
      encountered_empty_vjas = []
      previous_stop = nil
      vehicle_journey_at_stops.each do |vjas|
        sp = vjas.stop_point
        if vjas.arrival_time.nil? && vjas.departure_time.nil?
          encountered_empty_vjas << vjas
        else
          if encountered_empty_vjas.any?
            raise "Cannot extrapolate passing times without an initial time" if previous_stop.nil?
            distance_between_known = 0
            distance_from_last_known = 0
            cost = journey_pattern.costs_between previous_stop.stop_point, encountered_empty_vjas.first.stop_point
            raise "MISSING cost between #{previous_stop.stop_point.stop_area.registration_number} AND #{encountered_empty_vjas.first.stop_point.stop_area.registration_number}" unless cost.present?
            distance_between_known += cost[:distance].to_f
            cost = journey_pattern.costs_between encountered_empty_vjas.last.stop_point, sp
            raise "MISSING cost between #{encountered_empty_vjas.last.stop_point.stop_area.registration_number} AND #{sp.stop_area.registration_number}" unless cost.present?
            distance_between_known += cost[:distance].to_f
            distance_between_known += encountered_empty_vjas.each_cons(2).inject(0) do |sum, slice|
              cost = journey_pattern.costs_between slice.first.stop_point, slice.last.stop_point
              raise "MISSING cost between #{slice.first.stop_point.stop_area.registration_number} AND #{slice.last.stop_point.stop_area.registration_number}" unless cost.present?
              sum + cost[:distance].to_f
            end

            previous = previous_stop
            encountered_empty_vjas.each do |empty_vjas|
              cost = journey_pattern.costs_between previous.stop_point, empty_vjas.stop_point
              raise "MISSING cost between #{previous.stop_point.stop_area.registration_number} AND #{empty_vjas.stop_point.stop_area.registration_number}" unless cost.present?
              distance_from_last_known += cost[:distance]

              arrival_time_of_day = vjas.arrival_time_of_day
              previous_time_of_day = previous_stop.departure_time_of_day

              ratio = distance_from_last_known.to_f / distance_between_known.to_f
              delta = arrival_time_of_day-previous_time_of_day

              time_of_day = previous_time_of_day.add(seconds: ratio * delta)

              empty_vjas.update_attribute :arrival_time_of_day, time_of_day
              empty_vjas.update_attribute :departure_time_of_day, time_of_day

              previous = empty_vjas
            end
            encountered_empty_vjas = []
          end
          previous_stop = vjas
        end
      end
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
