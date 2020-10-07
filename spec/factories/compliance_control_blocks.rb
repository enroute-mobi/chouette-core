FactoryBot.define do
  factory :compliance_control_block do
    sequence(:name) { |n| "Compliance control block #{n}" }
    block_kind {'transport_mode'}
    transport_mode {TransportModeEnumerations.transport_modes.first}
    transport_submode {TransportModeEnumerations.transport_submodes.first}
    association :compliance_control_set
  end
end
