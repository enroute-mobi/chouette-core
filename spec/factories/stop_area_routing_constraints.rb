FactoryBot.define do
  factory :stop_area_routing_constraint do
    both_way {true}

    transient do
      stop_area_referential {nil}
      from_stop_area {nil}
      to_stop_area {nil}
    end

    before(:create) do |stop_area_routing_constraint, evaluator|
      stop_area_referential = evaluator.stop_area_referential
      stop_area_referential ||= evaluator.from_stop_area&.stop_area_referential
      stop_area_referential ||= evaluator.to_stop_area&.stop_area_referential
      stop_area_referential ||= create(:stop_area_referential)
      stop_area_routing_constraint.from = evaluator.from_stop_area
      stop_area_routing_constraint.to = evaluator.to_stop_area
      stop_area_routing_constraint.from ||= create(:stop_area, stop_area_referential: stop_area_referential)
      stop_area_routing_constraint.to ||= create(:stop_area, stop_area_referential: stop_area_referential)
    end
  end
end
