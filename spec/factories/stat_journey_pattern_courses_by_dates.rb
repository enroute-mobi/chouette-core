FactoryBot.define do
  factory :stat_journey_pattern_courses_by_date, class: 'Stat::JourneyPatternCoursesByDate' do
    journey_pattern {nil}
    date {"2018-10-23"}
    count {1}
  end
end
