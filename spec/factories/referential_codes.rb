FactoryGirl.define do
  factory :referential_code, class: ReferentialCode do
    sequence(:value) { |n| "Referential code value #{n}" }
    resource_type "Polymorphic"
    association :resource
    association :code_space
  end
end
