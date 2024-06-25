FactoryBot.define do
  factory :merge do
    workbench
    creator { 'test' }

    transient do
      new {nil}
    end

    after(:create) do |merge, evaluator|
      if evaluator.new
        merge.update new: evaluator.new
      end
    end
  end
end
