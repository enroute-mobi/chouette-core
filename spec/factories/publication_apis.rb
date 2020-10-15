FactoryBot.define do
  factory :publication_api do
    sequence(:name) { |n| "Publication API #{n}" }
    sequence(:slug) { |n| "publication_api_#{n}" }
  end
end
