FactoryGirl.define do
  factory :stop_area, :class => Chouette::StopArea do
    sequence(:objectid) { |n| "FR:#{n}:ZDE:#{n}:STIF" }
    sequence(:name) { |n| "stop_area_#{n}" }
    sequence(:registration_number) { |n| "test-#{n}" }
    area_type { Chouette::AreaType.commercial.sample }
    latitude {10.0 * rand}
    longitude {10.0 * rand}
    kind "commercial"
    confirmed_at { Time.now }

    association :stop_area_referential

    transient do
      referential nil
    end

    before(:create) do |stop_area, evaluator|
      stop_area.stop_area_referential = evaluator.referential.stop_area_referential if evaluator.referential
    end

    trait :deactivated do
      deleted_at { 1.hour.ago }
    end

    trait :with_parent do
      area_type  :zdep
      parent     { create  :stop_area, area_type: :gdl}
    end
  end
end
