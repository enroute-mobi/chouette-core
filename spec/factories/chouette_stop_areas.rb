FactoryGirl.define do
  factory :stop_area, :class => Chouette::StopArea do
    sequence(:objectid) { |n| "FR:#{n}:ZDE:#{n}:STIF" }
    sequence(:name) { |n| "stop_area_#{n}" }
    sequence(:registration_number) { |n| "test-#{n}" }
    area_type { Chouette::AreaType.commercial.sample }
    latitude {10.0 * rand}
    longitude {10.0 * rand}
    kind "commercial"

    association :stop_area_referential

    transient do
      referential nil
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
          stop_area_provider = StopAreaProvider.new name: referential.slug, objectid: "STIF-REFLEX:Operator:#{referential.slug}:LOC"
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
  end
end
