# frozen_string_literal: true

module Search
  class RoutingConstraintZone < Base
    # All search attributes
    attribute :text
    attribute :route_id

    attr_accessor :referential

    def searched_class
      ::Chouette::RoutingConstraintZone
    end

    def query(scope)
      Query::RoutingConstraintZone.new(scope) \
                                  .text(text) \
                                  .route_id(route_id)
    end

    def candidate_routes
      referential.routes
    end

    def routes
      candidate_routes.where(id: route_id)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
      attribute :route, joins: :route, column: 'routes.name'
      attribute :stop_points_count, column: Arel.sql('array_length(stop_point_ids, 1)')
    end
  end
end
