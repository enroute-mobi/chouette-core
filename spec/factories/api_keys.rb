FactoryBot.define do
  factory :api_key, class: ApiKey do
    name  { SecureRandom.urlsafe_base64 }
    association :workbench, factory: :workbench
  end
end
