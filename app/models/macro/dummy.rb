module Macro
  class Dummy < Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :expected_result
        enumerize :expected_result, in: %w{info warning error fail}, default: "info"

        option :target_model
        enumerize :target_model, in: %w{Line StopArea JourneyPattern Company}, default: "Line"
        validates :target_model, presence: true
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        raise "Raise error as expected" if options[:expected_result] == "fail"
        ::Macro::Message.transaction do
          models.select(:id, :name).find_each do |model|
            macro_messages.create(
              message_attributes: { name: model.name },
              criticity: options[:expected_result],
              source: model
            )
          end
        end
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize
      end

      def models
        @models ||= scope.send(model_collection)
      end
    end
  end
end
