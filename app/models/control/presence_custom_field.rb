module Control
  class PresenceCustomField < Control::Base

    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :target_custom_field_id

        validates :target_model, :target_custom_field_id, :model_attribute, presence: true
        enumerize :target_model, in: %w{ Line StopArea Company JourneyPattern VehicleJourney }

        delegate :collection_name, to: :model_attribute

        def model_attribute
          candidate_custom_fields.find_by(resource_type: target_model)
        end

        def candidate_custom_fields # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
          workgroup.custom_fields
        end

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

    class Run < Control::Base::Run
      include Options

      def run
        return unless custom_field

        faulty_models.find_each do |model|
          control_messages.create({
            message_attributes: {
              name: model.try(:name) || model.id,
              custom_field: custom_field.code,
            },
            criticity: criticity,
            source: model,
            message_key: :presence_custom_field
          })
        end
      end

      def faulty_models
        models.where("custom_field_values ->> ? IS NULL", custom_field.code)
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
