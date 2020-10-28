FactoryBot.define do
  factory :stop_area_provider do
    sequence(:objectid) { |n| "FR1:OrganisationalUnit:#{n}:LOC" }
    sequence(:name) { |n| "StopAreaProvider #{n}"}

    association :workbench
  end
end
