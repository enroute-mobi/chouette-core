# frozen_string_literal: true

module Chouette
  module Planner
    class Merger
      def initialize(maximum_distance: 250, walk_speed: 1.3)
        @maximum_distance = maximum_distance
        @walk_speed = walk_speed
      end

      attr_accessor :maximum_distance, :walk_speed

      def merge(journey, reverse_journey)
        merge = create journey, reverse_journey
        return nil unless merge.mergeable?

        # TODO: we could remove duplicated steps (like A, B, B@0)
        journey.merge(reverse_journey, merge_duration: merge.duration)
      end

      def create(journey, reverse_journey)
        # puts [journey.id, reverse_journey.id].inspect

        cache[[journey.id, reverse_journey.id]] ||= Merge.new(
          journey,
          reverse_journey,
          maximum_distance: maximum_distance,
          walk_speed: walk_speed
        )
      end

      def cache
        @cache ||= {}
      end

      class Merge
        def initialize(journey, reverse_journey, **attributes)
          @journey = journey
          @reverse_journey = reverse_journey

          attributes.each { |k, v| send "#{k}=", v }
        end

        attr_accessor :journey, :reverse_journey, :maximum_distance, :walk_speed

        def last
          @last ||= journey.last
        end

        def reverse_last
          @reverse_last ||= reverse_journey.last
        end

        def distance
          @distance ||= last.position.distance_with(reverse_last.position)
        end

        def mergeable?
          @mergeable ||= last == reverse_last || distance < maximum_distance
        end

        def duration
          distance / walk_speed
        end
      end
    end
  end
end
