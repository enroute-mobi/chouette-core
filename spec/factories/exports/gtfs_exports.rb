FactoryGirl.define do
  factory :gtfs_export, class: Export::Gtfs, parent: :export do
    options({duration: 90})
    type 'Export::Gtfs'
    association :parent, factory: :workgroup_export
    association :referential, factory: :workbench_referential
  end
end
