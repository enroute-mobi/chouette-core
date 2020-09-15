FactoryGirl.define do
  factory :netex_export_generic, class: Export::NetexGeneric, parent: :export do
    association :parent, factory: :workgroup_export
    options({duration: 90})
    type 'Export::NetexGeneric'
  end
end
