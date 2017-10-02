FactoryGirl.define do

  factory :vehicle_journey_control_wating_time, class: 'VehicleJourneyControl::WaitingTime' do
    association :compliance_control_set
    association :compliance_control_block
  end

  factory :vehicle_journey_control_delta, class: 'VehicleJourneyControl::Delta' do
    association :compliance_control_set
    association :compliance_control_block
  end
end
