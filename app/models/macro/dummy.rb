# frozen_string_literal: true

module Macro
  class Dummy < Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :expected_result
        enumerize :expected_result, in: %w[info warning error failed], default: 'info'

        option :target_model
        enumerize :target_model,
                  in: %w[StopArea Entrance ConnectionLink Line Company Network PointOfInterest Shape Document Route JourneyPattern VehicleJourney ServiceCount TimeTable], default: 'Line'

        validates :target_model, presence: true
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        raise 'Raise error as expected' if expected_result == 'failed'

        models.find_each do |model|
          macro_messages.create(
            message_attributes: { name: model.try(:name), result: expected_result },
            criticity: expected_result,
            source: model
          )
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
