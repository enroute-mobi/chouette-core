FactoryBot.define do
  factory :line_referential do
    sequence(:name) { |n| "Line Referential #{n}" }
    objectid_format {'stif_codifligne'}

    transient do
      member {nil}
    end

    after(:create) do |line_referential, evaluator|
      line_referential.add_member evaluator.member if evaluator.member
      line_referential.save
    end
  end
end
