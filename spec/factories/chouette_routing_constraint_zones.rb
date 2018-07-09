FactoryGirl.define do
  factory :routing_constraint_zone, class: Chouette::RoutingConstraintZone do
    sequence(:name) { |n| "Routing constraint zone #{n}" }
    sequence(:objectid) { |n| "organisation:RoutingConstraintZone:lineId-routeId-#{n}:LOC" }
    association :route, factory: :route
    after(:build) do |zone|
      route = Chouette::Route.find(zone.route_id)
      zone.stop_point_ids = route.stop_points.pluck(:id).first(2) unless zone.stop_point_ids.present?
    end
  end
end
