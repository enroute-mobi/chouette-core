FactoryBot.define do
  factory :stop_area, :class => Chouette::StopArea do
    sequence(:name) { |n| "stop_area_#{n}" }
    sequence(:public_code) { |n| "sa_#{n}" }
    sequence(:registration_number) { |n| "test-#{n}" }
    area_type { Chouette::AreaType.commercial.sample }
    latitude {10.0 * rand}
    longitude {10.0 * rand}
    compass_bearing {rand(0.0...359.9)}
    kind {"commercial"}
    confirmed_at { Time.now }
    city_name {'Bordeaux'}
    postal_region {'33063'}
    zip_code {'33800'}
    street_name {"Parc du couvent, Avenue Steve Biko"}
    url   { Faker::Internet.url }

    association :stop_area_provider

    transient do
      referential {nil}
    end

    before(:create) do |stop_area, evaluator|
      stop_area.stop_area_referential = evaluator.referential.stop_area_referential if evaluator.referential
    end

    after(:create) do |stop_area, evaluator|
      if evaluator.referential && evaluator.referential.workbench
        referential = evaluator.referential
        organisation = referential.workbench.organisation
        stop_area_provider = StopAreaProvider.where(name: referential.slug).last
        unless stop_area_provider
          stop_area_provider = StopAreaProvider.new name: referential.slug, objectid: "FR1:OrganisationalUnit:#{referential.slug}:LOC"
          stop_area_provider.stop_area_referential = referential.stop_area_referential
          organisation.sso_attributes ||= {}
          functional_scope = organisation.sso_attributes['stop_area_providers'] || "[]"
          functional_scope = JSON.parse functional_scope
          functional_scope << referential.slug
          organisation.sso_attributes['stop_area_providers'] = functional_scope.to_json
          organisation.save
        end
        stop_area_provider.stop_areas << stop_area
        stop_area_provider.save
      end
    end

    trait :deactivated do
      deleted_at { 1.hour.ago }
    end

    trait :with_parent do
      area_type  { :zdep }
      parent     { create  :stop_area, area_type: :gdl}
    end

    trait :zdep do
      kind {"commercial"}
      area_type {'zdep'}
    end

    trait :zdlp do
      kind {"commercial"}
      area_type {'zdlp'}
    end

    trait :lda do
      kind {"commercial"}
      area_type {'lda'}
    end

    trait :gdl do
      kind {"commercial"}
      area_type {'gdl'}
    end

    trait :deposit do
      kind {"non_commercial"}
      area_type {'deposit'}
    end

    trait :border do
      kind {"non_commercial"}
      area_type {'border'}
    end

    trait :service_area do
      kind {"non_commercial"}
      area_type {'service_area'}
    end

    trait :relief do
      kind {"non_commercial"}
      area_type {'relief'}
    end

    trait :other do
      kind {"non_commercial"}
      area_type {'other'}
    end
  end
end
