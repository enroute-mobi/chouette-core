# frozen_string_literal: true

module Macro
  class RemoveCode < Base
    module Options
      extend ActiveSupport::Concern

      included do # rubocop:disable Metrics/BlockLength
        option :target_model
        option :code_space_id

        enumerize :target_model, in: %w[
          Line
          LineGroup
          LineNotice
          Company
          StopArea
          StopAreaGroup
          Entrance
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
        ]

        validates :target_model, :code_space_id, presence: true

        def code_space
          @code_space ||= workgroup.code_spaces.find_by(id: code_space_id)
        end
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        models_with_code.find_each do |model|
          codes_count = model.codes.where(code_space_id: code_space_id).delete_all
          create_message(model, codes_count)
        end
      end

      def create_message(model, codes_count)
        model_name = model.try(:name) || model.try(:published_journey_name) ||
                     model.try(:comment) || model.try(:uuid) || model.try(:get_objectid)&.local_id

        attributes = {
          message_attributes: { name: model_name, codes_count: codes_count },
          source: model
        }

        attributes.merge!(criticity: 'error', message_key: 'error') if codes_count.zero?

        macro_messages.create!(attributes)
      end

      def models_with_code
        @models_with_code ||= models.with_code(code_space)
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
