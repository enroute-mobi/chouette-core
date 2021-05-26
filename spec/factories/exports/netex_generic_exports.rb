FactoryBot.define do
  factory :netex_generic_export, class: Export::NetexGeneric, parent: :export do
    association :referential, factory: :workbench_referential
    options {{profile: 'european', duration: 60}}
    type {'Export::NetexGeneric'}
  end
end
