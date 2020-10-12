FactoryBot.define do
  factory :compliance_check_resource do
    association :compliance_check_set
    sequence(:name) { |n| "Compliance check resource #{n}" }
    status {'OK'}
  end
end
