FactoryGirl.define do
  factory :api_key, class: Api::V1::ApiKey do
    token { "#{referential.id}-#{SecureRandom.hex}" }
    referential
  end
end
