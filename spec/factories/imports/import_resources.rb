FactoryBot.define do
  factory :import_resource, class: Import::Resource do
    association :import
    status {:WARNING}
    sequence(:name) { |n| "Import resource #{n}" }
    resource_type {'type'}
    reference {'reference'}
  end
end
