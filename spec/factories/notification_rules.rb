FactoryBot.define do
  factory :notification_rule do
    notification_type { 'hole_sentinel' }
    target_type { 'workbench' }
    operation_statuses { [] }
    association :workbench
    priority { 10 }
    period { (Date.today...Date.today + 10.days) }

    lines { [] }
  end
end
