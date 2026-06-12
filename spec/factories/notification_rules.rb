FactoryBot.define do
  factory :notification_rule do
    target_type { 'workbench' }
    operation_statuses { [] }
    association :workbench
    priority { 10 }

    lines { [] }
  end
end
