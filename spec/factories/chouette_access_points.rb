FactoryBot.define do

  factory :access_point, :class => Chouette::AccessPoint do
    latitude {10.0 * rand}
    longitude {10.0 * rand}
    sequence(:name) { |n| "AccessPoint #{n}" }
    access_type { "InOut" }
    sequence(:objectid) { |n| "FR:#{n}:ADL:#{n}:STIF" }
    association :stop_area, :factory => :stop_area
  end

end
