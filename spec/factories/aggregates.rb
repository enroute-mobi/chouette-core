FactoryBot.define do
  factory :aggregate do
    association :workgroup
    status { :successful }
    name { "MyString" }
    referentials { [ create(:referential) ] }
    new {nil}
    creator { 'test' }

    trait :successful do
      after(:create) do |a|
        a.update status: :successful
      end
    end

    trait :failed do
      after(:create) do |a|
        a.update status: :failed
      end
    end
  end
end
