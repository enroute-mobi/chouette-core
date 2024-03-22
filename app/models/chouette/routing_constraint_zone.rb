# frozen_string_literal: true

module Chouette
  class RoutingConstraintZone < Referential::ActiveRecord
    include ChecksumSupport
    include ObjectidSupport
    has_metadata

    belongs_to :route
    has_array_of :stop_points, class_name: 'Chouette::StopPoint', order_by: :position

    attr_accessor :allow_entire_journey

    belongs_to_array_in_many :vehicle_journeys, class_name: 'Chouette::VehicleJourney', array_name: :ignored_routing_contraint_zones

    def update_vehicle_journey_checksums
      vehicle_journeys.each(&:update_checksum!)
    end
    after_save :update_vehicle_journey_checksums
    after_commit :clean_ignored_routing_contraint_zone_ids, on: :destroy

    validates_presence_of :name, :stop_points, :route_id
    validate :stop_points_belong_to_route, :at_least_two_stop_points_selected
    validate :not_all_stop_points_selected, unless: :allow_entire_journey

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

    def checksum_attributes(db_lookup = true)
      [
        self.stop_points.map(&:stop_area_id)
      ]
    end

    has_checksum_children StopPoint

    def opposite_zone
      unless @opposite_zone_looked_up
        if route.opposite_route.present?
          stop_area_ids = stop_points.light.map(&:stop_area_id).uniq.sort

          @opposite_zone = route.opposite_route.routing_constraint_zones.find do |candidate|
            candidate.stop_points.light.map(&:stop_area_id).uniq.sort == stop_area_ids
          end
        end
        @opposite_zone_looked_up = true
      end

      @opposite_zone
    end

    def can_create_opposite_zone?
      return false if opposite_zone.present?
      return false unless route.opposite_route.present?

      stop_area_ids = stop_points.map(&:stop_area_id).uniq
      (route.opposite_route.stop_points.pluck(:stop_area_id) & stop_area_ids).uniq.size == stop_area_ids.size
    end

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
