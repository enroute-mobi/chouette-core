FactoryGirl.define do
  factory :referential do
    sequence(:name) { |n| "Test #{n}" }
    sequence(:slug) { |n| "test_#{n}" }
    sequence(:prefix) { |n| "test_#{n}" }
    association :line_referential
    association :stop_area_referential
    association :organisation
    time_zone "Europe/Paris"
    ready { true }
    objectid_format "stif_netex"

    factory :workbench_referential do
      association :workbench
      before :create do | ref |
        ref.workbench.organisation = ref.organisation
      end
    end

    trait :with_metadatas do
      ready { false }
      after(:create) do |ref|
        ref.metadatas = [create(:referential_metadata, referential: ref)]
        ref.update_attribute :ready, true
      end
    end
  end
end
