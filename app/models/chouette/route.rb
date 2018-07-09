module Chouette
  class Route < Chouette::TridentActiveRecord
    has_metadata

    include RouteRestrictions
    include ChecksumSupport
    include ObjectidSupport
    extend Enumerize

    if ENV["CHOUETTE_ROUTE_POSITION_CHECK"] == "true" || !Rails.env.production?
      after_commit do
        positions = stop_points.pluck(:position)
        Rails.logger.debug "Check positions in Route #{id} : #{positions.inspect}"
        if positions.size != positions.uniq.size
          raise "DUPLICATED stop_points positions in Route #{id} : #{positions.inspect}"
        end
      end
    end

    enumerize :direction, in: %i(straight_forward backward clockwise counter_clockwise north north_west west south_west south south_east east north_east)
    enumerize :wayback, in: %i(outbound inbound), default: :outbound

    def self.nullable_attributes
      [:published_name, :comment, :number, :name, :direction, :wayback]
    end

    belongs_to :line
    belongs_to :opposite_route, :class_name => 'Chouette::Route', :foreign_key => :opposite_route_id

    has_many :routing_constraint_zones, :dependent => :destroy
    has_many :journey_patterns, :dependent => :destroy
    has_many :vehicle_journeys, :dependent => :destroy do
      def timeless
        Chouette::Route.vehicle_journeys_timeless(proxy_association.owner.journey_patterns.pluck( :departure_stop_point_id))
      end
    end
    has_many :vehicle_journey_at_stops, through: :vehicle_journeys
    has_many :vehicle_journey_frequencies, :dependent => :destroy do
      # Todo : I think there is a better way to do this.
      def timeless
        Chouette::Route.vehicle_journeys_timeless(proxy_association.owner.journey_patterns.pluck( :departure_stop_point_id))
      end
    end
    has_many :stop_points, -> { order("position") }, :dependent => :destroy do
      def find_by_stop_area(stop_area)
        stop_area_ids = Integer === stop_area ? [stop_area] : (stop_area.children_in_depth + [stop_area]).map(&:id)
        where( :stop_area_id => stop_area_ids).first or
          raise ActiveRecord::RecordNotFound.new("Can't find a StopArea #{stop_area.inspect} in Route #{proxy_owner.id.inspect}'s StopPoints")
      end

      def between(departure, arrival)
        between_positions = [departure, arrival].collect do |endpoint|
          case endpoint
          when Chouette::StopArea
            find_by_stop_area(endpoint).position
          when  Chouette::StopPoint
            endpoint.position
          when Integer
            endpoint
          else
            raise ActiveRecord::RecordNotFound.new("Can't determine position in route #{proxy_owner.id} with #{departure.inspect}")
          end
        end
        where(" position between ? and ? ", between_positions.first, between_positions.last)
      end
    end

    has_many :vehicle_journey_at_stops, through: :vehicle_journeys

    has_many :stop_areas, -> { order('stop_points.position ASC') }, :through => :stop_points do
      def between(departure, arrival)
        departure, arrival = [departure, arrival].map do |endpoint|
          String === endpoint ? Chouette::StopArea.find_by_objectid(endpoint) : endpoint
        end
        proxy_owner.stop_points.between(departure, arrival).includes(:stop_area).collect(&:stop_area)
      end
    end

    has_many :time_tables, :through => :vehicle_journeys
    has_many :purchase_windows, :through => :vehicle_journeys

    accepts_nested_attributes_for :stop_points, :allow_destroy => :true

    validates_presence_of :name
    validates_presence_of :published_name
    validates_presence_of :line
    validates :wayback, inclusion: { in: self.wayback.values }
    after_commit :calculate_costs!,
      on: [:create, :update],
      if: ->() {
        # Ensure the call back doesn't run during a referential merge
        !referential.in_referential_suite? &&
          TomTom.enabled?
      }

    def clean!
      vehicle_journeys.find_each do |vj|
        vj.vehicle_journey_at_stops.delete_all
      end
      vehicle_journeys.delete_all
      journey_patterns.delete_all
      stop_points.delete_all
      routing_constraint_zones.delete_all
      Chouette::Route.where(opposite_route_id: self.id).update_all(opposite_route_id: nil)
      self.delete
    end

    def duplicate opposite=false
      overrides = {
        'opposite_route_id' => nil,
        'name' => I18n.t('activerecord.copy', name: self.name)
      }
      keys_for_create = attributes.keys - %w{id objectid created_at updated_at}
      atts_for_create = attributes
        .slice(*keys_for_create)
        .merge(overrides)
      if opposite
        atts_for_create[:wayback] = self.opposite_wayback
        atts_for_create[:name] = I18n.t('routes.opposite', name: self.name)
        atts_for_create[:published_name] = atts_for_create[:name]
        atts_for_create[:opposite_route_id] = self.id
      end
      new_route = self.class.create!(atts_for_create)
      duplicate_stop_points(for_route: new_route, opposite: opposite)
      new_route
    end

    def duplicate_stop_points(for_route:, opposite: false)
      stop_points.each(&duplicate_stop_point(for_route: for_route, opposite: opposite))
    end
    def duplicate_stop_point(for_route:, opposite: false)
      -> stop_point do
        stop_point.duplicate(for_route: for_route, opposite: opposite)
      end
    end

    def local_id
      "IBOO-#{self.referential.id}-#{self.line.get_objectid.local_id}-#{self.id}"
    end

    def geometry_presenter
      Chouette::Geometry::RoutePresenter.new self
    end

    @@opposite_waybacks = { outbound: :inbound, inbound: :outbound}
    def opposite_wayback
      @@opposite_waybacks[wayback.to_sym]
    end

    def opposite_route_candidates
      if opposite_wayback
        line.routes.where(opposite_route: [nil, self], wayback: opposite_wayback)
      else
        self.class.none
      end
    end

    validate :check_opposite_route
    def check_opposite_route
      return unless opposite_route && opposite_wayback
      unless opposite_route_candidates.include?(opposite_route)
        errors.add(:opposite_route_id, :invalid)
      end
    end

    def checksum_attributes
      values = self.slice(*['name', 'published_name', 'wayback']).values
      values.tap do |attrs|
        attrs << self.stop_points.sort_by(&:position).map{|sp| [sp.stop_area.user_objectid, sp.for_boarding, sp.for_alighting]}
        attrs << self.routing_constraint_zones.map(&:checksum).uniq.sort
      end
    end

    has_checksum_children StopPoint
    has_checksum_children RoutingConstraintZone

    def geometry
      points = stop_areas.map(&:to_lat_lng).compact.map do |loc|
        [loc.lng, loc.lat]
      end
      GeoRuby::SimpleFeatures::LineString.from_coordinates( points, 4326)
    end

    def time_tables
      ids = vehicle_journeys.joins(:time_tables).pluck('time_tables.id').uniq
      Chouette::TimeTable.where(id: ids)
    end

    def sorted_vehicle_journeys(journey_category_model)
      send(journey_category_model)
          .joins(:journey_pattern, :vehicle_journey_at_stops)
          .joins('LEFT JOIN "time_tables_vehicle_journeys" ON "time_tables_vehicle_journeys"."vehicle_journey_id" = "vehicle_journeys"."id" LEFT JOIN "time_tables" ON "time_tables"."id" = "time_tables_vehicle_journeys"."time_table_id"')
          .where("vehicle_journey_at_stops.stop_point_id=journey_patterns.departure_stop_point_id")
          .order("vehicle_journey_at_stops.departure_time")
    end

    def stop_point_permutation?( stop_point_ids)
      stop_points.map(&:id).map(&:to_s).sort == stop_point_ids.map(&:to_s).sort
    end

    def reorder!( stop_point_ids)
      return false unless stop_point_permutation?( stop_point_ids)

      stop_area_id_by_stop_point_id = {}
      stop_points.each do |sp|
        stop_area_id_by_stop_point_id.merge!( sp.id => sp.stop_area_id)
      end

      reordered_stop_area_ids = []
      stop_point_ids.each do |stop_point_id|
        reordered_stop_area_ids << stop_area_id_by_stop_point_id[ stop_point_id.to_i]
      end

      stop_points.each_with_index do |sp, index|
        if sp.stop_area_id.to_s != reordered_stop_area_ids[ index].to_s
          #result = sp.update_attributes( :stop_area_id => reordered_stop_area_ids[ index])
          sp.stop_area_id = reordered_stop_area_ids[ index]
          result = sp.save!
        end
      end

      return true
    end

    def full_journey_pattern
      journey_pattern = journey_patterns.find_or_create_by registration_number: self.number, name: self.name
      journey_pattern.stop_points = self.stop_points
      journey_pattern
    end

    def partial_journey_pattern_with stop_points
      signature = stop_points.map { |s| s.stop_area&.id }.join('-')
      candidate = journey_patterns.with_stop_areas_signature(signature).last
      candidate ||= begin
        journey_pattern = journey_patterns.build
        journey_pattern.stop_points = stop_points
        journey_pattern.registration_number = "#{self.number} - #{journey_patterns.size - 1}"
        journey_pattern.name = "#{self.name} - #{journey_patterns.size - 1}"
        journey_pattern.save!
        journey_pattern
      end
      candidate
    end

    def calculate_costs!
      RouteWayCostWorker.perform_async(referential.id, id)
    end

    def calculate_costs
      way_costs = TomTom.evaluate WayCost.from(stop_areas)
      costs = way_costs.inject({}) { |h,cost| h[cost.id] = { distance: cost.distance, time: cost.time } ; h }
      update_column :costs, costs
    end

    protected

    def self.vehicle_journeys_timeless(stop_point_id)
      all( :conditions => ['vehicle_journeys.id NOT IN (?)', Chouette::VehicleJourneyAtStop.where(stop_point_id: stop_point_id).pluck(:vehicle_journey_id)] )
    end

  end
end
