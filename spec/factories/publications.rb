FactoryGirl.define do
  factory :publication do
    association :publication_setup
    association :parent, factory: :aggregate

    ended_at Time.now

    trait :with_gtfs do
      association :publication_setup, factory: :publication_setup_gtfs
    end

    trait :with_idfm_netex_full do
      association :publication_setup, factory: :publication_setup_idfm_netex_full
    end

    trait :with_idfm_netex_line do
      association :publication_setup, factory: :publication_setup_idfm_netex_line
    end

    trait :with_netex_full do
      association :publication_setup, factory: :publication_setup_netex_full
    end
  end
end
