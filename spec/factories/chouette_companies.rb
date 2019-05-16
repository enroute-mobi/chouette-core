FactoryGirl.define do

  factory :company, :class => Chouette::Company do
    sequence(:name) { |n| "Company #{n}" }
    sequence(:short_name) { |n| "company-#{n}" }
    sequence(:code) { |n| "company_#{n}" }
    sequence(:objectid) { |n| "STIF:CODIFLIGNE:Company:#{n}" }
    sequence(:registration_number) { |n| "test-#{n}" }

    association :line_referential, :factory => :line_referential
  end

end
