FactoryBot.define do
  factory :notification_rule do
    notification_type { 'hole_sentinel' }
    association :workbench
    association :line
    period { (Date.today...Date.today + 10.days) }
  end
end