module Chouette
  class JourneyPattern < Chouette::TridentActiveRecord
    has_metadata
    include ChecksumSupport
    include CustomFieldsSupport
    include ObjectidSupport

    belongs_to :route
    has_many :vehicle_journeys, :dependent => :destroy
    has_many :vehicle_journey_at_stops, :through => :vehicle_journeys
    has_and_belongs_to_many :stop_points, -> { order("stop_points.position") }, :before_add => :vjas_add, :before_remove => :vjas_remove, :after_add => :shortcuts_update_for_add, :after_remove => :shortcuts_update_for_remove
    has_and_belongs_to_many :stop_point_lights, -> { light.order("stop_points.position") }, class_name: 'Chouette::StopPoint', join_table: :journey_patterns_stop_points, foreign_key: :journey_pattern_id
    has_many :stop_areas, through: :stop_points
    has_many :service_counts
    has_many :journey_pattern_stop_points, class_name: '::Chouette::JourneyPatternStopPoint'
    accepts_nested_attributes_for :journey_pattern_stop_points

    belongs_to :shape, optional: true
    belongs_to_public :shape

    scope :light, ->{ select(:id, :name, :route_id, :objectid) }

    scope :without_any_vehicle_journey, -> { joins('LEFT JOIN vehicle_journeys ON vehicle_journeys.journey_pattern_id = journey_patterns.id').where(vehicle_journeys: { id: nil } ) }
    scope :by_text, ->(text) { text.blank? ? all : where('lower(journey_patterns.published_name) LIKE :t or lower(journey_patterns.objectid) LIKE :t or lower(journey_patterns.registration_number) LIKE :t', t: "%#{text.downcase}%") }
    scope :with_associated_shape, -> { where.not(shape_id: nil) }
    scope :without_associated_shape, -> { where(shape_id: nil) }

    validates_presence_of :route
    validates_presence_of :name

    delegate :line, to: :route
    validates :stop_points, length: { minimum: 2, too_short: :minimum }, on: :update

    attr_accessor  :control_checked

    def local_id
      "local-#{self.referential.id}-#{self.route.line.get_objectid.local_id}-#{self.id}"
    end

    def checksum_attributes(db_lookup = true)
      values = self.slice(*['name', 'published_name', 'registration_number']).values
      values << self.stop_points.sort_by(&:position).map(&:stop_area_id)
      values << self.cleaned_costs
      values << self.shape_id if self.shape_id
      values.flatten
    end

    has_checksum_children StopPoint

    def self.state_update route, state
      transaction do
        state.each do |item|
          item.delete('errors')
          jp = find_by(objectid: item['object_id']) || state_create_instance(route, item)
          next if item['deletable'] && jp.persisted? && jp.destroy
          begin
            ::ActiveRecord::Base.transaction do
              # Update attributes and stop_points associations
              jp.assign_attributes(state_permited_attributes(item)) unless item['new_record']
              jp.state_stop_points_update(item) if jp.persisted?
              jp.save!
            end
          rescue => e
            Chouette::Safe.capture "JourneyPattern.state_update on Route #{route.id} failed", e
          end
          item['errors']   = jp.errors if jp.errors.any?
          item['checksum'] = jp.checksum
        end

        if state.any? {|item| item['errors']}
          state.map {|item| item.delete('object_id') if item['new_record']}
          raise ::ActiveRecord::Rollback
        end
      end

      state.map {|item| item.delete('new_record')}
      state.delete_if {|item| item['deletable']}
    end

    def self.state_permited_attributes item
      attrs = {
        name: item['name'],
        published_name: item['published_name'],
        registration_number: item['registration_number'],
        costs: item['costs'],
        shape_id: item['shape'].try(:[], 'id')
      }
      attrs["custom_field_values"] = Hash[
        *(item["custom_fields"] || {})
          .map { |k, v| [k, v["value"]] }
          .flatten
      ]

      attrs
    end

    def self.state_create_instance route, item
      # Flag new record, so we can unset object_id if transaction rollback
      jp = route.journey_patterns.create(state_permited_attributes(item))
      # FIXME
      # DefaultAttributesSupport will trigger some weird validation on after save
      # wich will call to valid?, wich will populate errors
      # In this case, we mark jp to be valid if persisted? return true
      jp.errors.clear if jp.persisted?

      jp.after_commit_objectid
      item['object_id']  = jp.objectid
      item['short_id']  = jp.get_objectid&.short_id
      item['new_record'] = true
      jp
    end

    def state_stop_points_update item
      item['stop_points'].each do |sp|
        stop_point = route.stop_points.find_by(stop_area_id: sp['id'], position: sp['position'])
        exist = stop_points.include?(stop_point)
        if !exist && sp['checked']
          stop_points << stop_point
        end
        if exist && !sp['checked']
          stop_points.delete(stop_point)
        end
      end
    end

    # TODO: this a workarround
    # otherwise, we loose the first stop_point
    # when creating a new journey_pattern
    def special_update
      bck_sp = self.stop_points.map {|s| s}
      self.update_attributes :stop_points => []
      self.update_attributes :stop_points => bck_sp
    end

    def departure_stop_point
      return unless departure_stop_point_id
      Chouette::StopPoint.find( departure_stop_point_id)
    end

    def arrival_stop_point
      return unless arrival_stop_point_id
      Chouette::StopPoint.find( arrival_stop_point_id)
    end

    def skip_save_shortcuts?
      @skip_save_shortcuts
    end

    def skip_save_shortcuts
      @skip_save_shortcuts = true
    end

    def shortcuts_update_for_add( stop_point)
      return if skip_save_shortcuts?

      stop_points << stop_point unless stop_points.include?( stop_point)

      ordered_stop_points = stop_points
      ordered_stop_points = ordered_stop_points.sort { |a,b| a.position <=> b.position} unless ordered_stop_points.empty?

      self.update_attributes( :departure_stop_point_id => (ordered_stop_points.first && ordered_stop_points.first.id),
                              :arrival_stop_point_id => (ordered_stop_points.last && ordered_stop_points.last.id))
    end

    def shortcuts_update_for_remove( stop_point)
      stop_points.delete( stop_point) if stop_points.include?( stop_point)

      ordered_stop_points = stop_points
      ordered_stop_points = ordered_stop_points.sort { |a,b| a.position <=> b.position} unless ordered_stop_points.empty?

      self.update_attributes( :departure_stop_point_id => (ordered_stop_points.first && ordered_stop_points.first.id),
                              :arrival_stop_point_id => (ordered_stop_points.last && ordered_stop_points.last.id))
    end

    def vjas_add(stop_point)
      return if new_record?

      vehicle_journeys.each do |vj|
        vj.vehicle_journey_at_stops.create :stop_point_id => stop_point.id
      end
    end

    def vjas_remove( stop_point)
      return if new_record?

      vehicle_journey_at_stops.where( :stop_point_id => stop_point.id).each do |vjas|
        vjas.destroy
      end
    end

    validate def all_costs_values_must_be_positive
      unless costs.empty?
        invalid_distances = false
        invalid_times = false
        costs.values.each do |val|
          break if invalid_distances || invalid_times
          invalid_distances = val['distance'].to_i < 0
          invalid_times = val['time'].to_i < 0
        end
        errors.add(:costs, I18n.t('activerecord.errors.models.journey_pattern.attributes.costs.distance')) if invalid_distances
        errors.add(:costs, I18n.t('activerecord.errors.models.journey_pattern.attributes.costs.time')) if invalid_times
      end
    end

    def costs
      read_attribute(:costs) || {}
    end

    def cleaned_costs
      out = {}
      costs.each do |k, v|
        out[k] = v.sort.select do |kk, vv|
          vv.present? && vv.to_i > 0
        end.to_h
      end
      out.select{|k, v| v.present?}
    end

    def costs_between start, finish
      key = "#{start.stop_area_id}-#{finish.stop_area_id}"
      costs[key]&.symbolize_keys || {}
    end

    def full_schedule?
      full = true
      stop_points.sort_by(&:position).inject(nil) do |start, finish|
        next finish unless start.present?
        costs = costs_between(start, finish)
        full = false unless costs.present?
        full = false unless costs[:time] && costs[:time] > 0
        finish
      end
      full
    end

    def known_distance?
      stop_points.sort_by(&:position).each_cons(2) do |departure, arrival|
        costs = costs_between(departure, arrival)
        return false unless costs && costs[:distance] && costs[:distance] > 0
      end
      
      true
    end

    def distance_between start, stop
      return 0 unless start.position < stop.position
      val = 0
      i = stop_points.index(start)
      _end = start
      while _end && _end != stop
        i += 1
        _start = _end
        _end = stop_points[i]
        val += costs_between(_start, _end)[:distance] || 0
      end
      val
    end

    def distance_to stop
      distance_between stop_points.first, stop
    end

    def journey_length
      i = 0
      j = stop_points.length - 1
      start = stop_points[i]
      stop = stop_points[j]
      while i < j && start.kind == "non_commercial"
        i+= 1
        start = stop_points[i]
      end

      while i < j && stop.kind == "non_commercial"
        j-= 1
        stop = stop_points[j]
      end
      return 0 unless start && stop
      distance_between start, stop
    end

    def use_default_costs!
      default_costs = {}
      stop_points.each_cons(2) do |previous_stop_point, next_stop_point|
        key = "#{previous_stop_point.stop_area_id}-#{next_stop_point.stop_area_id}"
        route_costs = route.costs[key]
        next unless route_costs

        # Route stores meters and seconds, JourneyPatterns use km and minute
        default_costs[key] = { distance: (route_costs.fetch("distance", 0) / 1000.0).round, time: route_costs.fetch("time", 0) / 60 }
      end
      update_column :costs, default_costs
    end

    def duplicate!
      dup = self.deep_clone(include: [:stop_points], except: [:objectid])

      dup.save!
      dup
    end


    def self.clean!
      current_scope = self.current_scope || all

      # There are several "DELETE CASCADE" in the schema like:
      #
      # TABLE "journey_patterns_stop_points" CONSTRAINT "jpsp_jp_fkey" FOREIGN KEY (journey_pattern_id) REFERENCES journey_patterns(id) ON DELETE CASCADE
      # TABLE "vehicle_journeys" CONSTRAINT "vj_jp_fkey" FOREIGN KEY (journey_pattern_id) REFERENCES journey_patterns(id) ON DELETE CASCADE
      #
      # The ruby code makes the expected deletions
      # and the delete cascade will be the fallback

      Chouette::VehicleJourney.where(journey_pattern: current_scope).clean!
      Chouette::JourneyPatternStopPoint.where(journey_pattern: current_scope).delete_all
      delete_all
    end

    def available_specific_stop_places
      stop_areas.map do |stop_area|
        [stop_area.id ,stop_area.children.to_a]
      end
    end

    def waypoints
      stop_points.each_with_index.map do |stop_point, position|
        stop_area = stop_point.stop_area
        longitude, latitude = stop_area.longitude, stop_area.latitude

        return nil unless longitude && latitude

        Waypoint.new({
          name: stop_area.name,
          position: position,
          waypoint_type: "waypoint",
          coordinates: [longitude, latitude],
          stop_area: stop_area
        })
      end
    end
  end
end
