FactoryBot.define do
  factory :export_message, class: Export::Message do
    association :export
    association :resource, factory: :export_resource
    criticity {:info}
  end
end
