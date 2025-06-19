# frozen_string_literal: true

module Macro
  class Dummy < Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :expected_result
        enumerize :expected_result, in: %w[info warning error failed], default: 'info'

        option :target_model
        enumerize :target_model, in: %w[
          Line
          LineGroup
          LineNotice
          Company
          BookingArrangement
          Network
          StopArea
          StopAreaGroup
          Entrance
          ConnectionLink
          Shape
          PointOfInterest
          ServiceFacilitySet
          AccessibilityAssessment
          Fare::Zone
          LineRoutingConstraintZone
          Document
          Contract
          Route
          JourneyPattern
          VehicleJourney
          TimeTable
        ], default: 'Line'

        validates :target_model, presence: true
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        raise 'Raise error as expected' if expected_result == 'failed'

        models.find_each do |model|
          messages.create(source: model, result: expected_result) do |message|
            message[:criticity] = expected_result
          end
        end
      end

      def model_collection
        @model_collection ||= target_model.underscore.gsub('/', '_').pluralize
      end

      def models
        @models ||= scope.send(model_collection)
      end
    end
  end
end
