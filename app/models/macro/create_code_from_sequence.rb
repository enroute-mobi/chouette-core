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

        # Target model should only used models outside referential for the moment See CHOUETTE-4640
        enumerize :target_model, in: %w[
          Line
          LineGroup
          LineNotice
          Company
          BookingArrangement
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
        ]

        validates :target_model, :code_space, :sequence, :format, presence: true

        def code_space
          @code_space ||= workgroup&.code_spaces&.find_by(id: code_space_id)
        end

        def sequence
          @sequence ||= workbench&.sequences&.find_by(id: sequence_id)
        end
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        return unless sequence

        models_without_code.find_each do |model|
          value = code_generator.value

          if value.nil?
            messages.create(source: model) do |message|
              message.error! message_key: :sequence_exhausted
            end

            break # Stop processing further models if sequence is exhausted
          end

          code = model.codes.create(code_space: code_space, value: value)

          messages.create(source: model, code_value: code.value) do |message|
            message.error! unless code.valid?
          end
        end
      end

      def models_without_code
        @models_without_code ||= models.where.not(id: models_with_code)
      end

      def existing_code_values
        @existing_code_values ||= models_with_code.pluck(models.code_table[:value])
      end

      def models_with_code
        @models_with_code ||= models_inside_workbench.with_code(code_space)
      end

      def model_collection
        @model_collection ||= target_model.underscore.gsub('/', '_').pluralize
      end

      def models
        @models ||= scope.send(model_collection)
      end

      def models_inside_workbench
        @models_inside_workbench ||= workbench.send(model_collection)
      end

      def code_generator
        @code_generator ||= CodeGenerator.new(sequence, format, existing_code_values)
      end

      protected

      def messages_options
        {
          resource_name_key: :model_name
        }
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
          # If no more code values, try to fetch a new batch
          if code_values.empty?
            @code_values = possible_code_values(offset, BATCH_SIZE)
            @offset += BATCH_SIZE

            # If still no values after fetching, return nil to indicate sequence is exhausted
            return nil if @code_values.empty?
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
