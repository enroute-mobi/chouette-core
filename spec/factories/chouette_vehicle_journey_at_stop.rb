FactoryGirl.define do
  factory :vehicle_journey_at_stop, :class => Chouette::VehicleJourneyAtStop do
    association :vehicle_journey, :factory => :vehicle_journey
    association :stop_point, :factory => :stop_point
    association :stop_area, strategy: :null
    departure_day_offset { 0 }
    departure_time       { Time.now }
    arrival_time         { Time.now - 1.hour }
  end
end
