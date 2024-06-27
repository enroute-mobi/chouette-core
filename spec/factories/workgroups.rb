FactoryBot.define do
  factory :workgroup do
    sequence(:name) { |n| "Workgroup ##{n}" }
    association :line_referential
    association :stop_area_referential
    association :owner, factory: :organisation
    export_types { %w[Export::Gtfs Export::NetexGeneric] }
  end
end
