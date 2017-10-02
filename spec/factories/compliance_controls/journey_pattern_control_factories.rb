
FactoryGirl.define do

  factory :journey_pattern_control_duplicates, class: 'JourneyPatternControl::Duplicates' do
    association :compliance_control_set
    association :compliance_control_block
  end

  factory :journey_pattern_control_vehicle_journey, class: 'JourneyPatternControl::VehicleJourney' do
    association :compliance_control_set
    association :compliance_control_block
  end

end
