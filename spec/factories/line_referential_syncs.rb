FactoryGirl.define do
  factory :line_referential_sync do
    association :line_referential, :factory => :line_referential
  end
end
