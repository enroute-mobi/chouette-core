FactoryBot.define do

  factory :line_notice, :class => Chouette::LineNotice do
    sequence(:title) { |n| "Line Notice title #{n}" }
    sequence(:content) { |n| "Line Notice content #{n}" }
    sequence(:objectid) { |n| "organisation:LineNotice:#{n}:LOC" }

    association :line_referential, :factory => :line_referential
  end
end
