# frozen_string_literal: true

module Control
  class TravelTime < Control::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :from_stop_area_id
        option :to_stop_area_id

        option :departure_time_of_day, serialize: TimeOfDay::Type::SecondOffset, fixed_serializer: true
        option :maximum_travel_time_in_minutes

        validates :from_stop_area_id, :to_stop_area_id, :departure_time_of_day, presence: true
        validates :maximum_travel_time_in_minutes, presence: true, numericality: true
      end

      def options_stop_areas
        workgroup.stop_area_referential.stop_areas
      end

      def from_stop_area
        @from_stop_area ||= options_stop_areas.find_by(id: from_stop_area_id)
      end

      def from
        Geo::Position.from from_stop_area
      end

      def to_stop_area
        @to_stop_area ||= options_stop_areas.find_by(id: to_stop_area_id)
      end

      def to
        Geo::Position.from to_stop_area
      end

      def maximum_travel_time
        maximum_travel_time_in_minutes&.minutes
      end

      def selected_from_stop_area
        @selected_from_stop_area = [from_stop_area].compact
      end

      def selected_to_stop_area
        @selected_to_stop_area = [to_stop_area].compact
      end
    end
    include Options

    class Run < Control::Base::Run
      include Options

      def time_zone
        from_stop_area.time_zone || to_stop_area.time_zone
      end

      def origin_time_of_day
        departure_time_of_day.force_zone(time_zone)
      end

      def run
        # The Control can be run in a Context without validity period (no Referential for example)
        return unless validity_period

        # The selected Stop Areas could be missing
        return unless from && to

        planner.solve

        anomalies.each do |date|
          control_messages.create(
            message_attributes: { date: date },
            criticity: criticity,
            source: from_stop_area,
            message_key: :travel_time
          )
        end
      end

      def anomalies
        validity_period.to_a.delete_if do |date|
          solutions.any? { |journey| journey.validity_period.include?(date) }
        end
      end

      delegate :stop_areas, :vehicle_journeys, :time_tables, :validity_period, to: :context
      delegate :solutions, to: :planner

      def planner
        @planner ||= Chouette::Planner.create(from, to, origin_time_of_day: origin_time_of_day) do |planner|
          planner.validity_period = Chouette::Planner::ValidityPeriod.from_period(validity_period)

          planner.extenders << Chouette::Planner::Extender::WalkableStopAreas.new(stop_areas)
          planner.extenders << Chouette::Planner::Extender::ByVehicleJourneyStopAreas.new(
            vehicle_journeys: vehicle_journeys,
            time_tables: time_tables,
            maximum_time_of_day: origin_time_of_day + maximum_travel_time
          )

          to_step = Chouette::Planner::Step.for(to) # Geo::Position.from doesn't support String parsing
          planner.evaluator = Chouette::Planner::Evaluator::Add.new(
            Chouette::Planner::Evaluator::RemainingDuration.new(with: to_step.position),
            Chouette::Planner::Evaluator::Duration.new
          )

          planner.on_solution do |journey|
            if journey.duration < maximum_travel_time
              planner.validity_period = planner.validity_period - journey.validity_period
            end
          end
        end
      end
    end
  end
end
