FactoryBot.define do
  factory :export_message, class: Export::Message do
    association :export
    criticity {:info}
  end
end
