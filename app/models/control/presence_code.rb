module Control
  class PresenceCode < Control::Base
    enumerize :target_model, in: %w{Line StopArea VehicleJourney}, default: "Line"
    option :target_model
    option :target_code_space_id

    validates :target_model, :target_code_space_id, presence: true

    validate :code_space_belong_to_workgroup

    def target_code_space
      control_list&.workbench&.workgroup.code_spaces.find_by_id(target_code_space_id)
    end

    private

    def code_space_belong_to_workgroup
      errors.add(:target_code_space_id, :invalid) unless target_code_space
    end


    class Run < Control::Base::Run
      option :target_model
      option :target_code_space_id

      def run
        faulty_models.find_each do |model|
          control_messages.create({
            message_attributes: { target_code_space: target_code_space },
            criticity: criticity,
            source: model,
          })
        end
      end

      def model_class
        @model_class ||=
          "Chouette::#{target_model}".constantize rescue nil || target_model.constantize
      end

      def code_model
        unless model_class == Chouette::VehicleJourney
          :codes
        else
          :referential_codes
        end
      end

      def faulty_models
        models.where.not(id: models.joins(:codes).where(code_model => { code_space_id: code_space }))
      end

      def code_space
        @code_space ||= workgroup.code_spaces.find_by(short_name: target_code_space)
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
