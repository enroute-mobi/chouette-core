FactoryBot.define do
  factory :publication_api_key do
    sequence(:name) { |n| "Publication API key #{n}" }
  end
end
