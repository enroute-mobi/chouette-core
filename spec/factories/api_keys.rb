FactoryGirl.define do
  factory :api_key, class: Api::V1::ApiKey do
    name  {SecureRandom.urlsafe_base64}
    token { "#{referential_id}-#{organisation_id}-#{SecureRandom.hex}" }
    referential
    organisation
  end
end
