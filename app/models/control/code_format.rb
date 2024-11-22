module Control

  class CodeFormat < Control::Base

    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :target_code_space_id
        option :expected_format, serialize: ActiveModel::Type::String

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

        validates :target_model, :target_code_space_id, :expected_format, presence: true

        def target_code_space
          @target_code_space ||= workgroup.code_spaces.find_by_id(target_code_space_id)
        end
      end
    end
    include Options

    class Run < Control::Base::Run
      include Options

      def run
        faulty_models.find_each do |model|
          control_messages.create({
            message_attributes: {
              name: model.try(:name) || model.try(:published_journey_name) || model.try(:comment),
              code_space_name: target_code_space.short_name,
              expected_format: expected_format
            },
            criticity: criticity,
            source: model,
            message_key: :code_format
          })
        end
      end

      def faulty_models
        models.with_code(target_code_space).where.not(models.code_table[:value].matches_regexp(expected_format))
      end

      def model_collection
        @model_collection ||= target_model.underscore.gsub('/', '_').pluralize
      end

      def models
        @models ||= context.send(model_collection)
      end
    end
  end
end
