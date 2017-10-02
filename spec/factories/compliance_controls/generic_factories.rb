
FactoryGirl.define do
  factory :generic_attribute_control_compliance_control do
    sequence(:name) { |n| "Compliance control #{n}" }
    type "GenericAttributeControl::MinMax"
    criticity :warning
    code "code"
    origin_code "code"
    comment "Text"
    association :compliance_control_set
    association :compliance_control_block
  end

  factory :generic_attribute_control_min_max, class: 'GenericAttributeControl::MinMax' do
    sequence(:name) { |n| "MinMax control #{n}" }
    association :compliance_control_set
    association :compliance_control_block
  end

  factory :generic_attribute_control_pattern, class: 'GenericAttributeControl::Pattern' do
    sequence(:name) { |n| "Pattern control #{n}" }
    association :compliance_control_set
    association :compliance_control_block
  end

  factory :generic_attribute_control_uniqueness, class: 'GenericAttributeControl::Uniqueness' do
    sequence(:name) { |n| "Uniqueness control #{n}" }
    association :compliance_control_set
    association :compliance_control_block
  end
end
