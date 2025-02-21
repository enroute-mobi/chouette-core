FactoryBot.define do
  factory :time_table_date, class: Chouette::TimeTableDate do
    association :time_table
    date { Time.zone.today }
  end
end
