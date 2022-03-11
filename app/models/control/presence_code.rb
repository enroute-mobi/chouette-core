module Control
  class PresenceCode < Control::Base
    enumerize :target_model, in: %w{Line StopArea VehicleJourney}, default: "Line"
    option :target_model
    option :target_code_space

    validates :target_model, :target_code_space, presence: true

    class Run < Control::Base::Run
      option :target_model
      option :target_code_space

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
        model_class == Chouette::VehicleJourney ?
          :referential_codes : :codes
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