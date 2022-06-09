FactoryBot.define do
  factory :line_provider do
    sequence(:name) { |n| "Line Provider #{n}" }
    sequence(:short_name) { |n| "Line Provider #{n}" }

    association :line_referential
    association :workbench
  end
end
