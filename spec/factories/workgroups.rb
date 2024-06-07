FactoryBot.define do
  factory :workgroup do
    sequence(:name) { |n| "Workgroup ##{n}" }
    association :line_referential
    association :stop_area_referential
    association :owner, factory: :organisation
    export_types { %w[Export::Gtfs Export::NetexGeneric] }
    nightly_aggregate_days { '1111111' }
  end
end
