FactoryBot.define do
  factory :compliance_check do
    sequence(:name) { |n| "Compliance check #{n}" }
    type { "Type" }
    criticity { "warning" }
    code { "code" }
    origin_code { "code" }
    comment { "Text" }
    iev_enabled_check { true }
    association :compliance_check_set

    factory :compliance_check_with_compliance_check_block do
      association :compliance_check_block
    end
  end
end
