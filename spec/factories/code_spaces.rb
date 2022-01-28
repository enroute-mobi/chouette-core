FactoryBot.define do
  factory :code_space, class: CodeSpace do
    sequence(:short_name) { |n| "short_name_#{n}" }
    association :workgroup
  end
end
