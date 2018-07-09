FactoryGirl.define do
  factory :time_table, :class => Chouette::TimeTable do
    sequence(:comment) { |n| "Timetable #{n}" }
    sequence(:objectid) { |n| "organisation:Timetable:#{n}:LOC" }
    sequence(:int_day_types) { (1..7).to_a.map{ |n| 2**(n+1)}.sum }
    calendar nil

    transient do
      dates_count 4
      periods_count 4
    end

    trait :empty do
      dates_count 0
      periods_count 0
    end

    after(:create) do |time_table, evaluator|
      unless time_table.dates.any?
        evaluator.dates_count.times do |i|
          time_table.dates  << create(:time_table_date, :time_table => time_table, :date => i.days.since.to_date, :in_out => true)
        end
      end

      start_date = Date.today
      end_date = start_date + 10

      unless time_table.periods.any?
        evaluator.periods_count.times do |i|
          time_table.periods << create(:time_table_period, :time_table => time_table, :period_start => start_date, :period_end => end_date)
          start_date = start_date + 20
          end_date = start_date + 10
        end
      end
      time_table.save_shortcuts
      time_table.update_checksum!
    end
  end

end
