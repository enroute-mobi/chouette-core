# frozen_string_literal: true

module Chouette
  module Planner
    class ValidityPeriod
      def initialize(dates = nil)
        @dates = Set.new(dates) if dates
      end

      def self.from_daysbit(daysbit)
        new daysbit.dates.to_a
      end

      def self.from_period(period)
        new period.to_a
      end

      def infinite?
        dates.nil?
      end

      def empty?
        dates.empty?
      end

      def inspect
        dates ? "[#{dates.map { |d| d.strftime('%Y-%m-%d') }.join(' ')}]" : '∞'
      end

      def day_count
        dates.size
      end

      alias to_s inspect

      def ==(other)
        other && dates == other.dates
      end

      def intersect(*others)
        intersected_dates = others.inject(dates) do |dates, other|
          unless other.infinite?
            if infinite?
              other.dates
            else
              dates & other.dates
            end
          else
            dates
          end
        end
        ValidityPeriod.new intersected_dates
      end

      def include?(date)
        return true if infinite?

        dates.include?(date)
      end

      def -(other)
        return self if infinite? || other.infinite?
        return self if other.empty?

        ValidityPeriod.new(dates - other.dates)
      end

      protected
      
      attr_reader :dates
    end
  end
end
