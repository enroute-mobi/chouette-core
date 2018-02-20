module Chouette
  class RoutingConstraintZone < Chouette::TridentActiveRecord
    has_paper_trail
    include ChecksumSupport
    include ObjectidSupport

    belongs_to :route
    has_array_of :stop_points, class_name: 'Chouette::StopPoint'

    validates_presence_of :name, :stop_points, :route_id
    # validates :stop_point_ids, length: { minimum: 2, too_short: I18n.t('activerecord.errors.models.routing_constraint_zone.attributes.stop_points.not_enough_stop_points') }
    validate :stop_points_belong_to_route, :not_all_stop_points_selected

    def local_id
      "IBOO-#{self.referential.id}-#{self.route.line.get_objectid.local_id}-#{self.route.id}-#{self.id}"
    end

    scope :order_by_stop_points_count, ->(direction) do
      order("array_length(stop_point_ids, 1) #{direction}")
    end

    scope :order_by_route_name, ->(direction) do
      joins(:route)
        .order("routes.name #{direction}")
    end

    def checksum_attributes
      [
        self.stop_points.map(&:stop_area).map(&:user_objectid)
      ]
    end

    def stop_points_belong_to_route
      return unless route

      errors.add(:stop_point_ids, I18n.t('activerecord.errors.models.routing_constraint_zone.attributes.stop_points.stop_points_not_from_route')) unless stop_points.all? { |sp| route.stop_points.include? sp }
    end

    def not_all_stop_points_selected
      return unless route

      errors.add(:stop_point_ids, I18n.t('activerecord.errors.models.routing_constraint_zone.attributes.stop_points.all_stop_points_selected')) if stop_points.length == route.stop_points.length
    end

    def stop_points_count
      stop_points.count
    end

    def route_name
      route.name
    end
  end
end
