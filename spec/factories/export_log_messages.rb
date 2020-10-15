FactoryBot.define do
  factory :export_log_message do
    association :export
    sequence(:key) { |n| "key_#{n}" }
  end
end
