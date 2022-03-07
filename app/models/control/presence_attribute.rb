module Control
  class PresenceAttribute < Control::Base
    enumerize :target_model, in: %w{Line StopArea JourneyPattern VehicleJourney Company}, default: "Line"
    option :target_model
    option :target_attribute

    validates :target_model, :target_attribute, presence: true

    class Run < Control::Base::Run
      option :target_model
      option :target_attribute

      def run
        model_class.find_each do |object|
          message = find_or_create_message(object)

          begin
            value = object.send(model_attribute.name)
            unless value.present?
              message.criticity = "warning"
              message.message_key = :no_presence_of_attribute
            end
          rescue
            message.criticity = "error"
            message.message_key = "invalid"
          end

          message.save if message.changed?
        end
      end

      def find_or_create_message(object)
        params = {
          message_attributes: { attribute_name: target_attribute },
          source: object,
        }

        message = self.control_messages.where(params).
          first_or_create(params.merge( criticity: "info",  message_key: :presence_of_attribute))
      end

      def model_attribute
        @model_attribute ||= ::ModelAttribute.find_by_code(model_attribute_code)
      end

      def model_attribute_code
        @model_attribute_code ||= "#{target_model.underscore}##{target_attribute}"
      end

      def model_class
        @model_class ||=
          "Chouette::#{target_model}".constantize rescue nil || target_model.constantize
      end
    end
  end
end
