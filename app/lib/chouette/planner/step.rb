# frozen_string_literal: true

module Chouette
  module Planner
    class Step
      def self.for(definition, **attributes)
        # case definition
        # else
        new position: Geo::Position.parse(definition), **attributes
        # end
      end

      attr_accessor :duration, :created_by

      def initialize(attributes = {})
        self.duration = 0

        attributes.each { |k, v| send "#{k}=", v }
      end

      attr_reader :position

      def position=(position)
        @position = Geo::Position.from position
      end

      def distance_with(other)
        position.distance_with(other.position)
      end

      def ==(other)
        distance_with(other) < 10
      end

      def validity_period
        @validity_period ||= ValidityPeriod.new
      end

      def inspect
        "#{@position} ⏱️#{duration}s"
      end

      def with_duration(duration)
        clone = dup
        clone.duration = duration
        clone
      end
    end
  end
end
