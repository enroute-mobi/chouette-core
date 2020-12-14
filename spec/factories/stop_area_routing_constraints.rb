FactoryBot.define do
  factory :stop_area_routing_constraint do
    both_way {true}

    transient do
      stop_area_provider {nil}
      from_stop_area {nil}
      to_stop_area {nil}
    end

    before(:create) do |stop_area_routing_constraint, evaluator|
      stop_area_provider = evaluator.stop_area_provider
      stop_area_provider ||= evaluator.from_stop_area&.stop_area_provider
      stop_area_provider ||= evaluator.to_stop_area&.stop_area_provider
      stop_area_provider ||= create(:stop_area_provider)

      stop_area_routing_constraint.stop_area_provider = stop_area_provider
      stop_area_routing_constraint.from = evaluator.from_stop_area
      stop_area_routing_constraint.to = evaluator.to_stop_area
      stop_area_routing_constraint.from ||= create(:stop_area, stop_area_provider: stop_area_provider)
      stop_area_routing_constraint.to ||= create(:stop_area, stop_area_provider: stop_area_provider)
    end
  end
end
