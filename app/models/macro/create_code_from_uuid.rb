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
          code = model.codes.create(code_space: code_space, value: format_code_space(model))
          create_message(model, code)
        end
      end

      def create_message(model, code)
        model_name = model.try(:name) || model.try(:published_journey_name) ||
                     model.try(:comment) || model.try(:uuid) || model.try(:get_objectid)&.local_id

        attributes = {
          message_attributes: { model_name: model_name, code_value: code.value },
          source: model
        }

        attributes.merge!(criticity: 'error', message_key: 'error') unless code.valid?

        macro_messages.create!(attributes)
      end

      def models_without_code
        @models_without_code ||= models.without_code(code_space)
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize
      end

      def models
        @models ||= scope.send(model_collection)
      end

      def uuid
        SecureRandom.uuid
      end

      def format_code_space(model)
        format.gsub('%{value}', uuid).gsub(CODE_SPACE_REGEXP) do # rubocop:disable Style/FormatStringToken
          next nil unless model.respond_to?(:line)

          if ::Regexp.last_match(1)
            model.line.codes.find { |c| c.code_space.short_name == ::Regexp.last_match(1) }&.value
          else
            model.line.registration_number
          end
        end
      end

      CODE_SPACE_REGEXP = /%{line.code(?::([^}]*))?}/.freeze
    end
  end
end
