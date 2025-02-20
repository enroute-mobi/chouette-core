# frozen_string_literal: true

module Chouette
  module Planner
    class Base
      include Measurable

      def initialize(from: nil, to: nil, **attributes)
        journeys << Journey.new(step: Step.for(from), origin_time_of_day: attributes.delete(:origin_time_of_day))
        reverse_journeys << Journey.new(step: Step.for(to), reverse: true)

        attributes.each { |k, v| send "#{k}=", v }

        @improve_runs = 0
      end

      def maximum_improve_runs
        4
      end

      def logger
        Rails.logger
      end

      attr_accessor :improve_runs, :evaluator

      def validity_period
        @validity_period ||= ValidityPeriod.new
      end

      attr_writer :validity_period

      def on_solution(&block)
        @solution_callback = block
      end

      def solution_callback
        @solution_callback ||= proc { |journey| }
      end

      def improve
        self.improve_runs += 1
        return false if improve_runs > maximum_improve_runs

        improvable = false

        logger.tagged("improve(#{improve_runs})") do
          merge
          improvable = extend
          evaluate

          logger.debug do
            "#{solutions.count} solutions - #{journeys.count} journeys - #{reverse_journeys.count} reverse journeys"
          end
        end

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

          reverse_journeys.each do |reverse_journey|
            merged_journey = merger.merge journey, reverse_journey
            next unless merged_journey

            solutions << merged_journey
            solution_callback.call merged_journey
            merged_performed = true
          end

          merged_performed
        end
      end
      measure :merge

      def extend_batch_size
        @extend_batch_size ||= 100
      end

      def extend
        if extenders.empty?
          journeys.clear
          return false
        end

        extendable_journeys = journeys.reject(&:extended?).first(extend_batch_size)
        extendable_journeys.each(&:extended!)

        logger.debug { "#{extendable_journeys.count} extendable journeys" }
        extendable_journeys.first(10).each do |extendable_journey|
          logger.debug { "* #{extendable_journey.inspect}" }
        end

        extenders.each do |extender|
          logger.tagged extender.class do
            Chouette::Benchmark.measure extender.class do
              extended_journeys = extender.extend extendable_journeys
              logger.debug { "#{extended_journeys.count} extended journeys" }
              journeys.concat extended_journeys
            end
          end
        end

        extendable_reverse_journeys = reverse_journeys.reject(&:extended?).first(extend_batch_size)
        extendable_reverse_journeys.each(&:extended!)

        extenders.each do |extender|
          logger.tagged 'reverse', extender.class do
            extended_reverse_journeys = extender.extend extendable_reverse_journeys
            logger.debug { "#{extended_reverse_journeys.count} extended reverse journeys by #{extender.class}" }

            reverse_journeys.concat extended_reverse_journeys
          end
        end

        extendable_journeys.present? || extendable_reverse_journeys.present?
      end

      def evaluate
        journeys.each do |journey|
          journey.cost = evaluator.call journey
        end

        journeys.sort_by!(&:cost)

        reverse_journeys.each do |journey|
          journey.cost = evaluator.call journey
        end

        reverse_journeys.sort_by!(&:cost)
      end
      measure :evaluate

      def extenders
        @extenders ||= []
      end

      def evaluator
        @evaluator ||= proc { |_journey| 0 }
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
