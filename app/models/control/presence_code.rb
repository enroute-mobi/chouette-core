module Control
  class PresenceCode < Control::Base

    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :target_code_space_id

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

        validates :target_model, :target_code_space, presence: true

        def target_code_space
          @target_code_space ||= workgroup&.code_spaces&.find_by_id(target_code_space_id)
        end
      end
    end
    include Options

    validate :code_space_belong_to_workgroup

    private

    def code_space_belong_to_workgroup
      errors.add(:target_code_space_id, :invalid) unless target_code_space
    end

    class Run < Control::Base::Run
      include Options

      def run
        faulty_models.find_each do |model|
          messages.create(source: model, code_space_name: target_code_space.short_name)
        end
      end

      def faulty_models
        models.without_code(target_code_space)
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
