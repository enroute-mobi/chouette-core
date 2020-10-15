FactoryBot.define do
  factory :export_resource, class: Export::Resource do
    sequence(:name) { |n| "Export resource #{n}" }
    association :export, factory: :netex_export
    status {:WARNING}
    resource_type {'type'}
    reference {'reference'}
  end
end
