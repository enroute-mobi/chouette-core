module Control
  class FormatAttribute < Control::Base

    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :target_attribute
        option :expected_format

        enumerize :target_model, in: %w{Line StopArea JourneyPattern VehicleJourney Company}
        validates :target_model, :target_attribute, :expected_format, :model_attribute, presence: true

        delegate :resource_name, :collection_name, to: :model_attribute

        def model_attribute_code
          @model_attribute_code ||= "#{target_model&.underscore}##{target_attribute}"
        end

        def model_attribute
          @model_attribute ||= ::ModelAttribute.find_by_code(model_attribute_code)
        end
      end
    end

    include Options

    class Run < Control::Base::Run
      include Options

      def run
        faulty_models.find_each do |model|
          control_messages.create!({
            message_attributes: {
              name: (model.name rescue model.id),
              target_attribute: target_attribute,
              expected_format: expected_format
            },
            criticity: criticity,
            source: model,
          })
        end
      end

      def faulty_models
        models
          .distinct
          .where
          .not("#{collection_name}.#{target_attribute} ~ ?", expected_format)
      end

      def models
        @models ||= context.send(collection_name)
      end
    end
  end
end
