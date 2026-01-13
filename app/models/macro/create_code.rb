# frozen_string_literal: true

module Macro
  class CreateCode < Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :source_attribute # TODO use ModelAttribute ?
        option :source_pattern
        option :target_code_space_id # TODO must be id or short_name of one of Workgroup CodeSpaces
        option :target_pattern

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
          Route
          JourneyPattern
          VehicleJourney
          TimeTable
        ]

        validates :target_model, :source_attribute, :code_space, presence: true

        def code_space
          @code_space ||= workgroup&.code_spaces&.find_by(id: target_code_space_id)
        end
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        # This Updater pattern made simple to test
        #
        # Could be optimize with a more complex logic:
        # - read all source value (with cursor)
        # - compute all target value
        # - create all required codes with inserter ?

        request = CreateCodeFromUuid::Run::RequestBuilder.new(workgroup, models, code_space, target_pattern).run
        request.find_in_batches do |batch|
          models.transaction do
            batch.each do |model|
              if source_value = source.value(model)
                code_value = target.value(model, source_value)
                code = model.codes.create(code_space: code_space, value: code_value)

                messages.create(source: model, code_value: code.value) do |message|
                  message.error! unless code.persisted?
                end
              end
            end
          end
        end
      end

      def source
        @source ||= Source.new(
          workgroup: workgroup,
          attribute: source_attribute,
          pattern: source_pattern,
        )
      end

      def target
        @target ||= Target.new(target_pattern)
      end

      def model_collection
        target_model.underscore.gsub('/', '_').pluralize
      end

      def models
        @models ||= scope.send(model_collection)
      end
    end

    class Source
      attr_accessor :workgroup, :attribute, :pattern
      def initialize(attributes = {})
        attributes.each { |k,v| send "#{k}=", v }
      end

      def value(model)
        apply_pattern raw_value(model)
      end

      def raw_value(model)
        unless code_space
          model.send attribute
        else
          model.codes.find_by(code_space: code_space)&.value
        end
      end

      def apply_pattern(value)
        if pattern_regexp && pattern_regexp =~ value
          $1
        else
          value
        end
      end

      def pattern_regexp
        @pattern_regexp ||= Regexp.new(pattern) if pattern.present?
      end

      def code_space_short_name
        if /^code:(.*)/ =~ attribute
          $1
        end
      end

      def code_space
        return unless workgroup
        @code_space ||= workgroup.code_spaces.find_by(short_name: code_space_short_name)
      end
    end

    class Target < CreateCodeFromUuid::Run::AbstractTarget
      def format?
        format.present?
      end

      def value(model, value) # rubocop:disable Metrics/MethodLength
        return value unless format?

        result = format.gsub(VALUE_REGEXP) do
          if ::Regexp.last_match(1) && ::Regexp.last_match(2)
            from = ::Regexp.new(::Regexp.last_match(1))
            to = ::Regexp.last_match(2)
            value.gsub(from, to)
          else
            value
          end
        end

        apply_format!(result, model)
      end
    end

    VALUE_REGEXP = %r@%{value(?://([^/]+)/([^}]*))?}@.freeze
  end
end
