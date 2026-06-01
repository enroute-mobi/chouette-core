# frozen_string_literal: true

module Macro
  class DefineVehicleJourneyName < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_format

        validates :target_format, presence: true
      end

    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        vehicle_journeys.find_each do |vehicle_journey|
          Updater.new(self, vehicle_journey, target_format).update
        end
      end

      def vehicle_journeys
        @vehicle_journeys ||= scope.vehicle_journeys
                                   .where.not(published_journey_identifier: [nil, ''])
      end

      protected

      def messages_options
        {
          resource_name_key: nil
        }
      end

      class Updater
        def initialize(macro_run, vehicle_journey, format)
          @macro_run = macro_run
          @vehicle_journey = vehicle_journey
          @format = format
        end
        attr_reader :macro_run, :vehicle_journey, :format

        delegate :messages, to: :macro_run

        def update
          success = vehicle_journey.update(published_journey_name: name)

          messages.create(
            source: vehicle_journey,
            vehicle_journey_id: vehicle_journey_id,
            attribute_value_after_change: name
          ) do |message|
            message.error! unless success
          end
        end

        def name
          @name ||= format.gsub('%{public_code}', vehicle_journey.published_journey_identifier)
        end

        def vehicle_journey_id
          vehicle_journey.get_objectid&.short_id
        end
      end

    end
  end
end
