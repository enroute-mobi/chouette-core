FactoryBot.define do
  factory :referential_cloning do
    association :source_referential, :factory => :referential
    association :target_referential, :factory => :referential
  end
end
