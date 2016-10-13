FactoryGirl.define do
  factory :line_referential do
    sequence(:name) { |n| "Line Referential #{n}" }
  end
end
