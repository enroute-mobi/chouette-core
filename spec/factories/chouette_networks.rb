FactoryBot.define do

  factory :network, :class => Chouette::Network do
    sequence(:name) { |n| "Network #{n}" }
    sequence(:objectid) { |n| "STIF:CODIFLIGNE:Network:#{n}" }
    sequence(:registration_number) { |n| "test-#{n}" }

    association :line_referential
    line_provider { association :line_provider, line_referential: line_referential }
    # association :line_provider, :factory => :line_provider, line_referential: line_referential
  end
end
