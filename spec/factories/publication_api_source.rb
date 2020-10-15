FactoryBot.define do
  factory :publication_api_source do
    association :publication_api
    association :publication
    association :export, factory: :gtfs_export
  end
end
