FactoryGirl.define do

  factory :company, :class => Chouette::Company do
    sequence(:name) { |n| "Company #{n}" }
    sequence(:short_name) { |n| "company-#{n}" }
    sequence(:code) { |n| "company_#{n}" }
    sequence(:objectid) { |n| "STIF:CODIFLIGNE:#{n}:LOC" }
    sequence(:registration_number) { |n| "test-#{n}" }

    default_contact_email { Faker::Internet.email }
    default_contact_url   { Faker::Internet.url }
    default_contact_phone { Faker::PhoneNumber.phone_number }

    association :line_referential, :factory => :line_referential
  end

end
