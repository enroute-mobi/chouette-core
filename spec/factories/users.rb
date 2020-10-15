require_relative '../support/permissions'

FactoryBot.define do
  factory :user do
    association :organisation
    sequence(:name) { |n| "chouette#{n}" }
    sequence(:username) { |n| "chouette#{n}" }
    sequence(:email) { |n| "chouette#{n}@dryade.priv" }
    password {"secret"}
    password_confirmation {"secret"}
    factory :allmighty_user do
      permissions {Support::Permissions.all_permissions}
    end
  end
end
