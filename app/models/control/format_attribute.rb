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

        delegate :collection_name, to: :model_attribute

        def model_attribute
          candidate_target_attributes.find_by(model_name: target_model, name: target_attribute)
        end

        def candidate_target_attributes # rubocop:disable Metrics/MethodLength
          Chouette::ModelAttribute.for(self.class.target_model.values).all do
            exclude 'StopArea', :parent
            exclude 'StopArea', :referent
          end
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
