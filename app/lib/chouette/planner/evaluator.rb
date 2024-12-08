module Chouette
  module Planner
    module Evaluator
      class Duration
        def call(journey)
          journey.duration
        end
      end

      class RemaingDuration
        def initialize(with:, speed: 8)
          @target = Geo::Position.from(with)
          @speed = speed
        end

        def call(journey)
          distance = @target.distance_with journey.last.position
          distance / @speed
        end
      end

      class Add
        def initialize(*evaluators)
          @evaluators = evaluators
        end

        def call(journey)
          @evaluators.map { |evaluator| evaluator.call(journey)  }.sum
        end
      end
    end
  end
end
