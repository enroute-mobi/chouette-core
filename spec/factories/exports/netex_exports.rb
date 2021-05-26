FactoryBot.define do
  factory :netex_export, class: Export::Netex, parent: :export do
    association :referential, factory: :workbench_referential
    options {{export_type: :full, duration: 60}}
    type {'Export::Netex'}
  end

  factory :idfm_netex_export_full, class: Export::Netex, parent: :export do
    association :referential, factory: :workbench_referential
    options {{export_type: :full, duration: 60}}
    type {'Export::Netex'}
  end

  factory :idfm_netex_export_line, class: Export::Netex, parent: :export do
    association :referential, factory: :workbench_referential
    options {{export_type: :line, duration: 60, line_code: 1}}
    type {'Export::Netex'}
  end
end
