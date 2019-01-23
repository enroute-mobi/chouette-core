FactoryGirl.define do
  factory :workgroup_export, class: Export::Workgroup, parent: :export do
    options({ duration: 90 })
    type 'Export::Workgroup'
    association :referential, factory: :workbench_referential
  end
end
