FactoryBot.define do
  factory :compliance_check_block do
    sequence(:name) { |n| "Compliance check block #{n}" }
    association :compliance_check_set
    block_kind {:transport_mode}
    transport_mode {:bus}
    transport_submode {'undefined'}
  end
end
