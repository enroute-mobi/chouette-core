FactoryGirl.define do

  factory :vehicle_journey_common, :class => Chouette::VehicleJourney do
    sequence(:objectid) { |n| "organisation:VehicleJourney:lineid-#{n}:LOC" }
    sequence(:published_journey_name) { |n| "VehicleJourney ##{n}" }

    factory :vehicle_journey_empty do
      association :journey_pattern, :factory => :journey_pattern

      after(:build) do |vehicle_journey|
        vehicle_journey.route = vehicle_journey.journey_pattern.route
      end

      factory :vehicle_journey do
        association :company, factory: :company
        transient do
          stop_arrival_time '01:00:00'
          stop_departure_time '03:00:00'
        end

        after(:create) do |vehicle_journey, evaluator|
          vehicle_journey.journey_pattern.stop_points.each_with_index do |stop_point, index|
            prev_stop = vehicle_journey.vehicle_journey_at_stops[index - 1]

            arrival_time   = prev_stop ? prev_stop[:departure_time] + 1.minute : evaluator.stop_arrival_time
            departure_time = prev_stop ? arrival_time + 1.minute : evaluator.stop_departure_time

            vehicle_journey.vehicle_journey_at_stops << create(:vehicle_journey_at_stop,
                   :vehicle_journey => vehicle_journey,
                   :stop_point      => stop_point,
                   :arrival_time    => "2000-01-01 #{arrival_time} UTC",
                   :departure_time  => "2000-01-01 #{departure_time} UTC")
          end
          vehicle_journey.update_checksum!
        end

        factory :vehicle_journey_odd do
          association :journey_pattern, :factory => :journey_pattern_odd
        end

        factory :vehicle_journey_even do
          association :journey_pattern, :factory => :journey_pattern_even
        end
      end
    end
  end
end

#      after(:build) do |vehicle_journey|
#        vehicle_journey.route_id = vehicle_journey.journey_pattern.route_id
#      end
#
#      after(:create) do |vehicle_journey|
#        vehicle_journey.journey_pattern.stop_points.each_with_index do |stop_point, index|
#          vehicle_journey.vehicle_journey_at_stops.create(:vehicle_journey_at_stop,
#                                                          :vehicle_journey => vehicle_journey,
#                                                          :stop_point => stop_point,
#                                                          :arrival_time => (-1 * index).minutes.ago,
#                                                          :departure_time => (-1 * index).minutes.ago)
#        end
#      end
#    end
#
#      after(:build) do |vehicle_journey|
#        vehicle_journey.route_id = vehicle_journey.journey_pattern.route_id
#      end
#
#      after(:create) do |vehicle_journey|
#        vehicle_journey.journey_pattern.stop_points.each_with_index do |stop_point, index|
#          vehicle_journey.vehicle_journey_at_stops.create(:vehicle_journey_at_stop,
#                                                          :vehicle_journey => vehicle_journey,
#                                                          :stop_point => stop_point,
#                                                          :arrival_time => (-1 * index).minutes.ago,
#                                                          :departure_time => (-1 * index).minutes.ago)
#        end
#      end
#    end
#
#  end
#end
#
