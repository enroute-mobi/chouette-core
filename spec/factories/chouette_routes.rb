FactoryBot.define do
  factory :route_common, :class => Chouette::Route do
    sequence(:name) { |n| "Route #{n}" }
    sequence(:published_name) { |n| "Long route #{n}" }
    sequence(:wayback) { |n| Chouette::Route.wayback.values[n % 2] }
    sequence(:objectid) { |n| "organisation:Route:lineId-routeId#{n}:LOC" }

    factory :route do
      transient do
        stop_points_count { 5 }
        referential { nil }
      end

      after(:build) do |route, evaluator|
        route.line ||= create(:line, referential: evaluator.referential)
      end

      after(:create) do |route, evaluator|
        create_list(:stop_point, evaluator.stop_points_count, route: route)
        route.reload
      end

      factory :route_with_journey_patterns do
        transient do
          journey_patterns_count {2}
        end

        after(:create) do |route, evaluator|
          create_list(:journey_pattern, evaluator.journey_patterns_count, route: route)
        end

      end

      trait :with_opposite do
        after(:create) do |route|
          opposite = create :route, line: route.line
          route.update opposite_route: opposite
        end
      end
    end

    factory :route_with_after_commit do
      sequence(:objectid) {nil}
      after(:create) do |route|
        route.run_callbacks(:commit)
      end
    end
  end
end
