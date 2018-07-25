FactoryGirl.define do
  factory :compliance_control_block do
    sequence(:name) { |n| "Compliance control block #{n}" }
    transport_mode NetexTransportModeEnumerations.transport_modes.first
    transport_submode NetexTransportSubmodeEnumerations.transport_submodes.first
    association :compliance_control_set
  end
end
