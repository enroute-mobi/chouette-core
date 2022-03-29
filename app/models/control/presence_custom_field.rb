module Control
  class PresenceCustomField < Control::Base
    enumerize :target_model, in: %w{ Line StopArea Company JourneyPattern VehicleJourney }, default: "Line"
    option :target_model
    option :target_custom_field_id

    validates :target_model, :target_custom_field_id, presence: true

    class Run < Control::Base::Run
      option :target_model
      option :target_custom_field_id

      delegate :custom_field, to: :control

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
