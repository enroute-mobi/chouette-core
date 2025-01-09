# frozen_string_literal: true

module Macro
  class CreateCodeFromSequence < Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :code_space_id
        option :format
        option :sequence_id

        enumerize :target_model, in: %w[
          Line
          LineGroup
          LineNotice
          Company
          StopArea
          StopAreaGroup
          Entrance
          Shape
          PointOfInterest
          ServiceFacilitySet
          AccessibilityAssessment
          Fare::Zone
          LineRoutingConstraintZone
          Document
          Contract
          Route
          JourneyPattern
          VehicleJourney
          TimeTable
        ]

        validates :target_model, :code_space_id, :sequence_id, :format, presence: true

        def code_space
          @code_space ||= workgroup.code_spaces.find_by(id: code_space_id)
        end

        def sequence
          @sequence ||= workbench.sequences.find_by(id: sequence_id)
        end
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        models_without_code.find_each do |model|
          code = model.codes.create(code_space: code_space, value: code_generator.value)
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
        @models_without_code ||= models.where.not(id: models_with_code)
      end

      def existing_code_values
        @existing_code_values ||= models_with_code.pluck(models.code_table[:value])
      end

      def models_with_code
        @models_with_code || models.with_code(code_space)
      end

      def model_collection
        @model_collection ||= target_model.underscore.gsub('/', '_').pluralize
      end

      def models
        @models ||= scope.send(model_collection)
      end

      def code_generator
        @code_generator ||= CodeGenerator.new(sequence, format, existing_code_values)
      end

      class CodeGenerator
        def initialize(sequence, format, existing_code_values)
          @sequence = sequence
          @format = format
          @existing_code_values = existing_code_values
        end

        attr_reader :sequence, :format, :existing_code_values

        BATCH_SIZE = 1000

        def value
          unless code_values.any?
            @code_values = possible_code_values(offset, BATCH_SIZE)
            @offset += BATCH_SIZE
          end

          @code_values.shift
        end

        def code_values
          @code_values ||= []
        end

        def offset
          @offset ||= 1
        end

        def possible_code_values(offset, limit)
          sequence.values(offset: offset, limit: limit)
                  .map { |value| format_code_space(value) }
                  .select { |value| existing_code_values.exclude? value }
        end

        def format_code_space(value)
          format.gsub('%{value}', value.to_s)
        end
      end
    end
  end
end
