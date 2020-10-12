FactoryBot.define do
  factory :referential do
    sequence(:name) { |n| "Test #{n}" }
    sequence(:slug) { |n| "test_#{n}" }
    sequence(:prefix) { |n| "test_#{n}" }
    association :line_referential
    association :stop_area_referential
    association :organisation
    time_zone {"Europe/Paris"}
    ready { true }
    objectid_format {"stif_netex"}
    transient do
      status {:active}
    end

    trait :bare do
      bare {true}
    end

    after(:create) do |referential, evaluator|
      referential.send "#{evaluator.status}!"
    end

    factory :workbench_referential do
      association :workbench
      before :create do | ref |
        ref.workbench.update organisation: ref.organisation
      end
      after :create do | ref |
        ref.workbench.workgroup.update line_referential: ref.line_referential
      end
    end
  end
end
