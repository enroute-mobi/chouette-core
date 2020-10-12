FactoryBot.define do
  factory :time_table_period, class: Chouette::TimeTablePeriod do
    association :time_table
    period_start       { Date.today }
    period_end         { Date.today + 1.month }
  end
end
