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
            if time_of_day.is_a?(Hash) && time_of_day.keys == [1, 2]
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
        faulty_models.find_each do |model|
          control_messages.create(
            message_attributes: {
              name: model.try(:published_journey_name) || model.id
            },
            criticity: criticity,
            source: model,
            message_key: :passing_times_in_time_range
          )
        end
      end

      def faulty_models
        context.vehicle_journeys.where(id: vehicle_journey_ids)
      end

      def vehicle_journey_ids
        VehicleJourneys.new(
          context,
          vehicle_journey_at_stops,
          after.second_offset,
          before.second_offset
        ).vehicle_journey_ids
      end

      class VehicleJourneys
        def initialize(context, vehicle_journey_at_stops, after_second_offset, before_second_offset)
          @context = context
          @vehicle_journey_at_stops = vehicle_journey_at_stops
          @after_second_offset = after_second_offset
          @before_second_offset = before_second_offset
        end
        attr_reader :context, :vehicle_journey_at_stops, :after_second_offset, :before_second_offset

        def vehicle_journey_ids
          context.vehicle_journey_at_stops
            .joins(stop_point: :stop_area)
            .where.not("#{second_offset_range} @> #{departure_second_offset} and #{second_offset_range} @> #{arrival_second_offset}")
            .select(:vehicle_journey_id)
            .distinct
            .from(base_query)
        end

        def base_query
          "(#{vehicle_journey_at_stops.to_sql}) AS vehicle_journey_at_stops"
        end

        def second_offset_range
          "'[#{lower},#{upper}]'::int4range"
        end
  
        def lower
          (after_second_offset.blank? || after_second_offset == 43920)  ? '' : after_second_offset
        end

        def upper
          (before_second_offset.blank? || before_second_offset == 43920) ? '' : before_second_offset
        end

        def departure_second_offset
          <<~SQL
            (
              EXTRACT(HOUR FROM departure_time AT TIME ZONE COALESCE(stop_areas.time_zone, 'UTC')) * 3600 +
              EXTRACT(MINUTE FROM departure_time AT TIME ZONE COALESCE(stop_areas.time_zone, 'UTC')) * 60 +
              EXTRACT(SECOND FROM departure_time AT TIME ZONE COALESCE(stop_areas.time_zone, 'UTC'))
            )::integer
          SQL
        end
  
        def arrival_second_offset
          <<~SQL
            (
              EXTRACT(HOUR FROM arrival_time AT TIME ZONE COALESCE(stop_areas.time_zone, 'UTC')) * 3600 +
              EXTRACT(MINUTE FROM arrival_time AT TIME ZONE COALESCE(stop_areas.time_zone, 'UTC')) * 60 +
              EXTRACT(SECOND FROM arrival_time AT TIME ZONE COALESCE(stop_areas.time_zone, 'UTC'))
            )::integer
          SQL
        end
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

          delegate :vehicle_journey_at_stops, to: :context
        end

        class All < Base
          def vehicle_journey_at_stops
            super
          end
        end

        class First < Base
          def vehicle_journey_at_stops
            super.departures
          end
        end

        class Last < Base
          def vehicle_journey_at_stops
            super.arrivals
          end
        end
      end
    end
  end
end
