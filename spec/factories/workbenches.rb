FactoryGirl.define do
  factory :workbench do
    sequence(:name) { |n| "Workbench #{n}" }

    association :organisation, :factory => :organisation
  end
end
