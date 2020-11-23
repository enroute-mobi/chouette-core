FactoryBot.define do
  factory :stop_area_referential, :class => StopAreaReferential do
    sequence(:name) { |n| "StopArea Referential #{n}" }
    objectid_format {'netex'}

    transient do
      member {nil}
    end

    after(:create) do |stop_area_referential, evaluator|
      stop_area_referential.add_member evaluator.member if evaluator.member
      stop_area_referential.save
    end
  end
end
