module Control
  class PresenceCustomField < Control::Base
    enumerize :target_model, in: %w{ Line StopArea Company JourneyPattern VehicleJourney }, default: "Line"
    option :target_model
    option :target_custom_field_id

    validates :target_model, :target_custom_field_id, presence: true
    validate :custom_field_is_present_in_workgroup

    def target_custom_field
      CustomField.where(id: target_custom_field_id, workgroup_id: control_list.workbench.workgroup_id).first
    end

    private

    def custom_field_is_present_in_workgroup
      errors.add(:target_custom_field_id, :invalid) unless target_custom_field
    end 

    class Run < Control::Base::Run
      option :target_model
      option :target_custom_field_id

      def run
        return unless custom_field

        faulty_models.find_each do |model|
          control_messages.create({
            message_attributes: { target_custom_field: target_custom_field },
            criticity: criticity,
            source: model,
          })
        end
      end

      def custom_field
        workgroup.custom_fields.find_by_code(target_custom_field)
      end

      def faulty_models
        models.where("custom_field_values ->> '#{target_custom_field}' IS NULL")
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
