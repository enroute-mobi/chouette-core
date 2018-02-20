module Chouette
  class JourneyPattern < Chouette::TridentActiveRecord
    has_paper_trail
    include ChecksumSupport
    include JourneyPatternRestrictions
    include ObjectidSupport
    # FIXME http://jira.codehaus.org/browse/JRUBY-6358
    self.primary_key = "id"

    belongs_to :route
    has_many :vehicle_journeys, :dependent => :destroy
    has_many :vehicle_journey_at_stops, :through => :vehicle_journeys
    has_and_belongs_to_many :stop_points, -> { order("stop_points.position") }, :before_add => :vjas_add, :before_remove => :vjas_remove, :after_add => :shortcuts_update_for_add, :after_remove => :shortcuts_update_for_remove
    has_many :stop_areas, through: :stop_points

    validates_presence_of :route
    validates_presence_of :name

    #validates :stop_points, length: { minimum: 2, too_short: :minimum }, on: :update
    enum section_status: { todo: 0, completed: 1, control: 2 }

    attr_accessor  :control_checked

    def local_id
      "IBOO-#{self.referential.id}-#{self.route.line.get_objectid.local_id}-#{self.id}"
    end

    def checksum_attributes
      values = self.slice(*['name', 'published_name', 'registration_number']).values
      values << self.stop_points.sort_by(&:position).map(&:stop_area).map(&:user_objectid)
      values.flatten
    end

    def self.state_update route, state
      transaction do
        state.each do |item|
          item.delete('errors')
          jp = find_by(objectid: item['object_id']) || state_create_instance(route, item)
          next if item['deletable'] && jp.persisted? && jp.destroy
          # Update attributes and stop_points associations
          jp.update_attributes(state_permited_attributes(item)) unless item['new_record']
          jp.state_stop_points_update(item) if !jp.errors.any? && jp.persisted?
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
      {
        name: item['name'],
        published_name: item['published_name'],
        registration_number: item['registration_number'],
        costs: item['costs']
      }
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
      item['short_id']  = jp.get_objectid.short_id
      item['new_record'] = true
      jp
    end

    def state_stop_points_update item
      item['stop_points'].each do |sp|
        exist = stop_area_ids.include?(sp['id'])
        next if exist && sp['checked']

        stop_point = route.stop_points.find_by(stop_area_id: sp['id'])
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

    def shortcuts_update_for_add( stop_point)
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

    def vjas_add( stop_point)
      return if new_record?

      vehicle_journeys.each do |vj|
        vjas = vj.vehicle_journey_at_stops.create :stop_point_id => stop_point.id
      end
    end

    def vjas_remove( stop_point)
      return if new_record?

      vehicle_journey_at_stops.where( :stop_point_id => stop_point.id).each do |vjas|
        vjas.destroy
      end
    end

    def costs
      read_attribute(:costs) || {}
    end

    def costs_between start, finish
      key = "#{start.stop_area_id}-#{finish.stop_area_id}"
      costs[key]&.symbolize_keys || {}
    end

    def full_schedule?
      full = true
      stop_points.order(:position).inject(nil) do |start, finish|
        next finish unless start.present?
        costs = costs_between(start, finish)
        full = false unless costs.present?
        full = false unless costs[:distance] && costs[:distance] > 0
        full = false unless costs[:time] && costs[:time] > 0
        finish
      end
      full
    end

    def set_distances distances
      raise "inconsistent data: #{distances.count} values for #{stop_points.count} stops" unless distances.count == stop_points.count
      prev = distances[0].to_i
      _costs = self.costs
      distances[1..-1].each_with_index do |distance, i|
        distance = distance.to_i
        relative = distance - prev
        prev = distance
        start, stop = stop_points[i..i+1]
        key = "#{start.stop_area_id}-#{stop.stop_area_id}"
        _costs[key] ||= {}
        _costs[key]["distance"] = relative
      end
      self.costs = _costs
    end
  end
end
