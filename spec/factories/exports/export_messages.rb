FactoryBot.define do
  factory :export_message, class: Export::Message do
    association :export, factory: :netex_export
    criticity {:info}
  end
end
