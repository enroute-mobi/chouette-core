FactoryBot.define do
  factory :journey_pattern_control_duplicates, class: 'JourneyPatternControl::Duplicates' do
    association :compliance_control_set
  end

  factory :journey_pattern_control_vehicle_journey, class: 'JourneyPatternControl::VehicleJourney' do
    association :compliance_control_set
  end
end
