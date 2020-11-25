FactoryBot.define do
  factory :stop_area_provider do
    sequence(:name) { |n| "StopAreaProvider #{n}"}

    association :workbench
    association :stop_area_referential
  end
end
