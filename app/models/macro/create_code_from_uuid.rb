# frozen_string_literal: true

module Macro
  class CreateCodeFromUuid < Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :code_space_id
        option :format

        enumerize :target_model, in: %w[StopArea Line Company Route JourneyPattern TimeTable VehicleJourney]

        validates :target_model, :code_space_id, :format, presence: true

        def code_space
          @code_space ||= workgroup.code_spaces.find_by(id: code_space_id)
        end
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        models_without_code.find_each do |model|
          code = model.codes.create(code_space: code_space, value: format_code_space(uuid))
          create_message(model, code)
        end
      end

      def create_message(model, code)
        attributes = {
          message_attributes: { model_name: model.name, code_value: code.value },
          source: model
        }

        attributes.merge!(criticity: 'error', message_key: 'error') unless code.valid?

        macro_messages.create!(attributes)
      end

      def models_without_code
        @models_without_code ||= models.where.not(id: models_with_code)
      end

      def models_with_code
        @models_with_code || models.joins(:codes).where(codes: {code_space: code_space}).distinct
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize
      end

      def models
        @models ||= scope.send(model_collection)
      end

      def uuid
        @uuid ||= SecureRandom.uuid
      end

      def format_code_space(uuid)
        format.gsub('%{value}', uuid)
      end
    end
  end
end
