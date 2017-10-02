FactoryGirl.define do
  factory :routing_constraint_zone_control_unactivated_stop_point,
    class: 'routingConstraintZoneControl::UnactivatedStopPoint' do
      association :compliance_control_set
      association :compliance_control_block
  end

  factory :routing_constraint_zone_control_minimum_length, class: 'routingConstraintZoneControl::MinimumLength' do
    association :compliance_control_set
    association :compliance_control_block
  end

  factory :routing_constraint_zone_control_maximum_length, class: 'routingConstraintZoneControl::MaximumLength' do
    association :compliance_control_set
    association :compliance_control_block
  end
end
