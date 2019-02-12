FactoryGirl.define do

  factory :company, :class => Chouette::Company do
    sequence(:name) { |n| "Company #{n}" }
    sequence(:short_name) { |n| "company-#{n}" }
    sequence(:code) { |n| "company_#{n}" }
    sequence(:objectid) { |n| "STIF:CODIFLIGNE:Company:#{n}" }
    sequence(:registration_number) { |n| "test-#{n}" }

    email { Faker::Internet.email }
    url   { Faker::Internet.url }
    phone { Faker::PhoneNumber.phone_number }

    association :line_referential, :factory => :line_referential
  end

end
