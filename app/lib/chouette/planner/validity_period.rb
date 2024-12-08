# frozen_string_literal: true

module Chouette
  module Planner
    class ValidityPeriod
      def initialize(days_bit = nil)
        @days_bit = days_bit
      end

      def infinite?
        days_bit.nil?
      end

      def empty?
        days_bit&.empty?
      end

      def inspect
        days_bit ? "#{days_bit.from}:#{days_bit.bitset}" : '∞'
      end

      alias to_s inspect

      def ==(other)
        other && days_bit == other.days_bit
      end

      def intersect(*others)
        others.inject(self) do |validity_period, other|
          validity_period._intersect other
        end
      end

      protected

      def _intersect(other)
        if days_bit
          if other.days_bit
            ValidityPeriod.new(days_bit.intersect(other.days_bit))
          else
            self
          end
        else
          other
        end
      end

      attr_reader :days_bit
    end
  end
end
