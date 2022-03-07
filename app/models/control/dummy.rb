module Control
  class Dummy < Control::Base
    option :expected_result
    enumerize :expected_result, in: %w{warning error fail}, default: "warning"

    option :target_model
    enumerize :target_model, in: %w{Line StopArea JourneyPattern Company}, default: "Line"

    class Run < Control::Base::Run
      option :target_model

      def run
        raise "Raise error as expected" if options[:expected_result] == "fail"

        models.select(:id, :name).find_each do |model|
          control_messages.create(
            message_attributes: model.attributes,
            criticity: criticity,
            source: model
          )
        end
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize
      end

      def models
        @models ||= context.send(model_collection)
      end
    end
  end
end
