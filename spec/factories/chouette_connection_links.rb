FactoryBot.define do
  factory :connection_link, :class => Chouette::ConnectionLink do
    sequence(:name) { |n| "Connection link #{n}" }
    sequence(:objectid) { |n| "test:ConnectionLink:#{n}:loc" }

	  link_type { ["mixed", "underground", "overground"].sample }
	  link_distance { rand(1..500) }
	  default_duration { rand(0..5)*60 }

	  association :stop_area_provider
    association :departure, :factory => :stop_area
    association :arrival, :factory => :stop_area
  end
end
