FactoryBot.define do
  factory :publication do
    association :publication_setup
    association :parent, factory: :aggregate

    ended_at {Time.now}

    trait :with_gtfs do
      association :publication_setup, factory: :publication_setup_gtfs
    end

    trait :with_gtfs_line do
      association :publication_setup, factory: :publication_setup_gtfs_by_lines
    end

    trait :with_netex_generic do
      association :publication_setup, factory: :publication_setup_netex_generic
    end
    
  end
end
