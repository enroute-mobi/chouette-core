module Control
  class PresenceCustomField < Control::Base

    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :target_custom_field_id

        validates :target_model, :target_custom_field_id, presence: true
        enumerize :target_model, in: %w{ Line StopArea Company JourneyPattern VehicleJourney }
      end

      def custom_field
        return unless workgroup.present?

        workgroup.custom_fields.find_by_id(target_custom_field_id)
      end
    end
    include Options

    validate :custom_field_is_present_in_workgroup

    private

    def custom_field_is_present_in_workgroup
      errors.add(:target_custom_field_id, :invalid) unless custom_field
    end

    def workgroup
      control_list.workbench&.workgroup
    end

    class Run < Control::Base::Run
      include Options

      def run
        return unless custom_field

        faulty_models.find_each do |model|
          control_messages.create({
            message_attributes: { target_custom_field: custom_field.code },
            criticity: criticity,
            source: model,
          })
        end
      end

      def custom_field
        workgroup.custom_fields.find_by_id(target_custom_field_id)
      end

      def faulty_models
        models.where("custom_field_values ->> '#{custom_field.code}' IS NULL")
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize.to_sym
      end

      def models
        @models ||= context.send(model_collection)
      end
    end
  end
end
