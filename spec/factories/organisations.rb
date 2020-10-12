FactoryBot.define do
  factory :organisation do
    sequence(:name) { |n| "Organisation #{n}" }
    sequence(:code) { |n| "000#{n}" }
    factory :org_with_lines do
      sso_attributes { { 'functional_scope' => %w{STIF:CODIFLIGNE:Line:C00108 STIF:CODIFLIGNE:Line:C00109}.to_json } }
    end
  end
end
