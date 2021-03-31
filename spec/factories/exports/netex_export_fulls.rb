FactoryBot.define do
  factory :netex_export_full, class: Export::NetexFull, parent: :export do
    association :parent, factory: :workgroup_export
    options {{}}
    type {'Export::NetexFull'}
  end
end
