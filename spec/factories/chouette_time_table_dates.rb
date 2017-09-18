FactoryGirl.define do
  factory :time_table_date, class: Chouette::TimeTableDate do
    association :time_table
    date do
      time_table.dates.last.date + 1.day
    end
  end
end
