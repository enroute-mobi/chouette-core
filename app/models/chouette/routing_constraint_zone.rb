module Chouette
  class RoutingConstraintZone < Chouette::TridentActiveRecord
    has_metadata
    include ChecksumSupport
    include ObjectidSupport

    belongs_to :route
    has_array_of :stop_points, class_name: 'Chouette::StopPoint', order_by: :position

    belongs_to_array_in_many :vehicle_journeys, class_name: 'Chouette::VehicleJourney', array_name: :ignored_routing_contraint_zones

    def update_vehicle_journey_checksums
      vehicle_journeys.each(&:update_checksum!)
    end
    after_save :update_vehicle_journey_checksums
    after_commit :clean_ignored_routing_contraint_zone_ids, on: :destroy

    validates_presence_of :name, :stop_points, :route_id
    validate :stop_points_belong_to_route, :not_all_stop_points_selected, :at_least_two_stop_points_selected

    def local_id
      "local-#{self.referential.id}-#{self.route&.line&.get_objectid&.local_id}-#{self.route_id}-#{self.id}"
    end

    scope :order_by_stop_points_count, ->(direction) do
      order("array_length(stop_point_ids, 1) #{direction}")
    end

    scope :order_by_route_name, ->(direction) do
      joins(:route)
        .order("routes.name #{direction}")
    end

    def clean_ignored_routing_contraint_zone_ids
      vehicle_journeys.find_each do |vj|
        vj.update ignored_routing_contraint_zone_ids: vj.ignored_routing_contraint_zone_ids - [self.id]
      end
    end

    def checksum_attributes
      [
        self.stop_points.map(&:stop_area).map(&:id)
      ]
    end

    has_checksum_children StopPoint

    def stop_points_belong_to_route
      return unless route

      errors.add(:stop_point_ids, I18n.t('activerecord.errors.models.routing_constraint_zone.attributes.stop_points.stop_points_not_from_route')) unless stop_points.all? { |sp| route.stop_points.include? sp }
    end

    def not_all_stop_points_selected
      return unless route

      errors.add(:stop_point_ids, I18n.t('activerecord.errors.models.routing_constraint_zone.attributes.stop_points.all_stop_points_selected')) if stop_points.length == route.stop_points.length
    end

    def at_least_two_stop_points_selected
      return unless route
      return unless route.stop_points.length > 2

      errors.add(:stop_point_ids, I18n.t('activerecord.errors.models.routing_constraint_zone.attributes.stop_points.not_enough_stop_points')) if stop_points.length < 2
    end

    def stop_points_count
      stop_points.count
    end

    def route_name
      route.name
    end
  end
end
