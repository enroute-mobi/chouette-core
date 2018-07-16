FactoryGirl.define do
  factory :gtfs_export, class: Export::GTFS, parent: :export do
    association :parent, factory: :workgroup_export
    duration 90
  end
end
