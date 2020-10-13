FactoryBot.define do
  factory :code_space, class: CodeSpace do
    sequence(:short_name) { |n| "short_name #{n}" }
    association :workgroup
  end
end
