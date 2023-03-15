# frozen_string_literal: true

module Control
  class PassingTimesInTimeRange < Control::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :passing_time_scope
        option :before, serialize: Proc.new { |t| TimeOfDay.parse(t).without_utc_offset }
        option :after,  serialize: Proc.new { |t| TimeOfDay.parse(t).without_utc_offset }

        enumerize :passing_time_scope, in: %w[all first last]

        %w[before after].each do |option|
          define_method "#{option}=" do |time_of_day|
            if time_of_day.is_a?(Hash) && time_of_day.keys == [1,2]
              time_of_day = TimeOfDay.new(time_of_day[1], time_of_day[2]).without_utc_offset
            end

            options[option] = time_of_day.to_s
          end
        end
      end
    end
    include Options

    validate :before_and_after_present
    validate :time_of_day_for_before_and_after

    private

    def before_and_after_present
      if before.blank?
        errors.add(:before, :invalid) 
      elsif after.blank?
        errors.add(:after, :invalid)
      end
    end

    def time_of_day_for_before_and_after
      if before.present? && !before.is_a?(TimeOfDay)
        errors.add(:before, :invalid)
      elsif after.present? && !after.is_a?(TimeOfDay)
        errors.add(:after, :invalid)
      end
    end

    class Run < Control::Base::Run
      include Options

      def run
        faulty_models.includes(:vehicle_journey).find_each do |model|
          control_messages.create(
            message_attributes: {
              name: model.id,
              arrival_time: model.arrival_time,
              departure_time: model.departure_time
            },
            criticity: criticity,
            source: model,
            message_key: :passing_times_in_time_range
          )
        end
      end

      def faulty_models
        vehicle_journey_at_stops.where(
          "departure_time < :start_date OR arrival_time > :end_date",
          { start_date: start_date, end_date: end_date }
        )
      end

      def start_date
        "#{(Date.current + after.day_offset.days)} #{after.hour}:#{after.min}"
      end

      def end_date
        "#{(Date.current + before.day_offset.days)} #{before.hour}:#{before.min}"
      end

      def vehicle_journey_at_stops
        VehicleJourneyAtStops.for(context, passing_time_scope)
      end

      class VehicleJourneyAtStops

        def self.for(context, passing_time_scope)
          const_get(passing_time_scope.classify)
            .new(context)
            .vehicle_journey_at_stops
        end

        class Base
          def initialize(context)
            @context = context
          end
          attr_reader :context
        end

        class All < Base
          def vehicle_journey_at_stops
            context.vehicle_journey_at_stops
          end
        end

        class First < Base
          def vehicle_journey_at_stops
            context.vehicle_journey_at_stops.departures
          end
        end

        class Last < Base
          def vehicle_journey_at_stops
            context.vehicle_journey_at_stops.arrivals
          end
        end
      end
    end
  end
end