# frozen_string_literal: true

module Chouette
  module Planner
    class Base
      def initialize(from: nil, to: nil, **attributes)
        attributes.each { |k, v| send "#{k}=", v }

        journeys << Journey.new(step: Step.for(from))
        reverse_journeys << Journey.new(step: Step.for(to), reverse: true)

        @improve_runs = 0
      end

      def maximum_improve_runs
        10
      end

      attr_accessor :improve_runs

      def improve
        self.improve_runs += 1
        return false if improve_runs > maximum_improve_runs

        merge
        improvable = extend
        evaluate

        improvable
      end

      def solve
        # TODO: we need a "complete" solution, for example for all the expected ValidityPeriod
        improvable = true
        improvable = improve while improvable

        solutions.present?
      end

      def merge
        journeys.delete_if do |journey|
          merged_performed = false

          reverse_journeys.delete_if do |reverse_journey|
            merged_journey = merger.merge journey, reverse_journey
            if merged_journey
              solutions << merged_journey
              merged_performed = true
            end

            merged_journey.present?
          end

          merged_performed
        end
      end

      def extend_batch_size
        @extend_batch_size ||= 1000
      end

      def extend
        if extenders.empty?
          journeys.clear
          return false
        end

        extendable_journeys = journeys.reject(&:extended?).first(extend_batch_size)
        extendable_journeys.each(&:extended!)

        extenders.each do |extender|
          extended_journeys = extender.extend extendable_journeys
          journeys.concat extended_journeys
        end

        extendable_reverse_journeys = reverse_journeys.reject(&:extended?).first(extend_batch_size)
        extendable_reverse_journeys.each(&:extended!)

        extenders.each do |extender|
          extended_reverse_journeys = extender.extend extendable_reverse_journeys
          reverse_journeys.concat extended_reverse_journeys
        end

        extendable_journeys.present? || extendable_reverse_journeys.present?
      end

      def evaluate
        journeys.each do |journey|
          evaluator.call journey
        end

        reverse_journeys.each do |journey|
          evaluator.call journey
        end
      end

      def extenders
        @extenders ||= []
      end

      def evaluator
        @evaluator ||= proc { |journey| }
      end

      def merger
        @merger || Merger.new
      end

      def journeys
        @journeys ||= []
      end

      def reverse_journeys
        @reverse_journeys ||= []
      end

      def solutions
        @solutions ||= []
      end
    end
  end
end
