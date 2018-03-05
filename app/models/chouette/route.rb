
module Chouette
  class Route < Chouette::TridentActiveRecord
    has_paper_trail
    include RouteRestrictions
    include ChecksumSupport
    include ObjectidSupport

    extend Enumerize
    extend ActiveModel::Naming

    enumerize :direction, in: %i(straight_forward backward clockwise counter_clockwise north north_west west south_west south south_east east north_east)
    enumerize :wayback, in: %i(outbound inbound), default: :outbound


    def self.nullable_attributes
      [:published_name, :comment, :number, :name, :direction, :wayback]
    end

    belongs_to :line
    belongs_to :opposite_route, :class_name => 'Chouette::Route', :foreign_key => :opposite_route_id

    has_many :routing_constraint_zones
    has_many :journey_patterns, :dependent => :destroy
    has_many :vehicle_journeys, :dependent => :destroy do
      def timeless
        Chouette::Route.vehicle_journeys_timeless(proxy_association.owner.journey_patterns.pluck( :departure_stop_point_id))
      end
    end
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
    has_many :stop_areas, -> { order('stop_points.position ASC') }, :through => :stop_points do
      def between(departure, arrival)
        departure, arrival = [departure, arrival].map do |endpoint|
          String === endpoint ? Chouette::StopArea.find_by_objectid(endpoint) : endpoint
        end
        proxy_owner.stop_points.between(departure, arrival).includes(:stop_area).collect(&:stop_area)
      end
    end

    accepts_nested_attributes_for :stop_points, :allow_destroy => :true

    validates_presence_of :name
    validates_presence_of :published_name
    validates_presence_of :line

    # validates_presence_of :direction
    # validates_presence_of :wayback

    validates :wayback, inclusion: { in: self.wayback.values }

  def duplicate
    overrides = {
      'opposite_route_id' => nil,
      'name' => I18n.t('activerecord.copy', name: self.name)
    }
    keys_for_create = attributes.keys - %w{id objectid created_at updated_at}
    atts_for_create = attributes
      .slice(*keys_for_create)
      .merge(overrides)
    new_route = self.class.create!(atts_for_create)
    duplicate_stop_points(for_route: new_route)
    new_route
  end

    def duplicate_stop_points(for_route:)
      stop_points.each(&duplicate_stop_point(for_route: for_route))
    end
    def duplicate_stop_point(for_route:)
      -> stop_point do
        stop_point.duplicate(for_route: for_route)
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
        attrs << self.routing_constraint_zones.map(&:checksum)
      end
    end

    def geometry
      points = stop_areas.map(&:to_lat_lng).compact.map do |loc|
        [loc.lng, loc.lat]
      end
      GeoRuby::SimpleFeatures::LineString.from_coordinates( points, 4326)
    end

    def time_tables
      vehicle_journeys.joins(:time_tables).map(&:"time_tables").flatten.uniq
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

    protected

    def self.vehicle_journeys_timeless(stop_point_id)
      all( :conditions => ['vehicle_journeys.id NOT IN (?)', Chouette::VehicleJourneyAtStop.where(stop_point_id: stop_point_id).pluck(:vehicle_journey_id)] )
    end

  end
end
