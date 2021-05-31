FactoryBot.define do
  factory :export_message, class: Export::Message do
    association :export, factory: :netex_export
    association :resource, factory: :export_resource
    criticity {:info}
  end
end
