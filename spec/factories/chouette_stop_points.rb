FactoryBot.define do
  factory :stop_point, :class => Chouette::StopPoint do
    sequence(:objectid) { |n| "test:StopPoint:#{n}:loc" }
    association :stop_area, :factory => :stop_area, area_type: "zdep"
    association :route
  end
end
