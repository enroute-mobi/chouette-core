# frozen_string_literal: true

module Control
  class PassingTimesInTimeRange < Control::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :passing_time_scope
        option :before, serialize: TimeOfDay::Type::SecondOffset
        option :after,  serialize: TimeOfDay::Type::SecondOffset

        enumerize :passing_time_scope, in: %w[all first last]
        validates :passing_time_scope, presence: true

        %w[before after].each do |option|
          define_method "#{option}=" do |time_of_day|
            if time_of_day.is_a?(Hash) && time_of_day.keys == [1,2]
              time_of_day = TimeOfDay.new(time_of_day[1], time_of_day[2]).without_utc_offset.second_offset
            end

            super time_of_day
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
              name: model.vehicle_journey.try(:published_journey_name) || model.vehicle_journey.id
            },
            criticity: criticity,
            source: model.vehicle_journey,
            message_key: :passing_times_in_time_range
          )
        end
      end

      def faulty_models
        vehicle_journey_at_stops
          .select('*')
          .from(base_query)
          .where(
            "departure_second_offset < :after_second_offset OR arrival_second_offset > :before_second_offset",
            before_second_offset: before_second_offset, after_second_offset: after_second_offset
          )
      end

      def base_query
        <<~SQL
          (
            SELECT
              vehicle_journey_at_stops.*,
              ((departure_day_offset * 24 + date_part( 'hour', departure_time)) * 60 + date_part('min', departure_time)) * 60 AS departure_second_offset,
              ((arrival_day_offset * 24 + date_part( 'hour', arrival_time)) * 60 + date_part('min', arrival_time)) * 60 AS arrival_second_offset
            FROM vehicle_journey_at_stops
          ) AS vehicle_journey_at_stops
        SQL
      end

      def after_second_offset
        after.second_offset
      end

      def before_second_offset
        before.second_offset
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
