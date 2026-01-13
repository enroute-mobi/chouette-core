# frozen_string_literal: true

module Macro
  class CreateCodeFromUuid < Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :code_space_id
        option :format

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

        validates :target_model, :code_space, :format, presence: true

        def code_space
          @code_space ||= workgroup&.code_spaces&.find_by(id: code_space_id)
        end
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        request = RequestBuilder.new(workgroup, models, code_space, format).run
        request.find_each do |model|
          code_value = target.value(model)
          code = model.codes.create(code_space: code_space, value: code_value)

          messages.create(source: model, code_value: code.value) do |message|
            message.error! unless code.valid?
          end
        end
      end

      def model_collection
        @model_collection ||= target_model.underscore.gsub('/', '_').pluralize
      end

      def models
        @models ||= scope.send(model_collection)
      end

      def target
        @target ||= Target.new(format)
      end

      class AbstractTarget
        def initialize(format)
          @format = format
        end
        attr_reader :format

        def apply_format!(result, model)
          CODE_SPACE_REGEXPS.each do |association, regexp|
            result.gsub!(regexp) do
              if ::Regexp.last_match(1)
                model.send("#{association}_code_#{::Regexp.last_match(1)}")
              else
                model.send("#{association}_registration_number")
              end
            end
          end
          result.freeze
        end
      end

      class Target < AbstractTarget
        def value(model)
          result = format.gsub('%{value}', uuid) # rubocop:disable Style/FormatStringToken

          apply_format!(result, model)
        end

        def uuid # rubocop:disable Rails/Delegate
          SecureRandom.uuid
        end
      end

      protected

      def messages_options
        {
          resource_name_key: :model_name
        }
      end

      class RequestBuilder
        def initialize(workgroup, models, code_space, format)
          @workgroup = workgroup
          @models = models
          @code_space = code_space
          @format = format
          @included_associations = Set.new
          @included_codes = Hash.new { |h, k| h[k] = Set.new }
        end
        attr_reader :workgroup, :models, :code_space, :format

        def code_space_by_short_name(code_space_short_name)
          @code_spaces ||= workgroup.code_spaces.index_by(&:short_name)
          @code_spaces[code_space_short_name]
        end

        def run
          request = models
          request = without_code(request)
          request = preload_pattern_codes(request)
          request = select_all_model_columns(request)
          request
        end

        def without_code(request)
          request.without_code(code_space)
        end

        def preload_pattern_codes(request) # rubocop:disable Metrics/MethodLength
          return request unless format

          CODE_SPACE_REGEXPS.each do |association, regexp|
            format.scan(regexp) do
              request = include_association(request, association)

              request = if ::Regexp.last_match(1)
                          include_and_select_association_code(request, association, ::Regexp.last_match(1))
                        else
                          select_association_registration_number(request, association)
                        end
            end
          end

          request
        end

        def select_all_model_columns(request)
          request.select("#{models.klass.quoted_table_name}.*")
        end

        private

        def include_association(request, association)
          return request if @included_associations.include?(association)
          return request unless models.klass.reflections.key?(association)

          @included_associations << association
          request.left_joins(association.to_sym)
        end

        def include_and_select_association_code(request, association, code_space_short_name) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
          return request if @included_codes[association].include?(code_space_short_name)

          @included_codes[association] << code_space_short_name

          if @included_associations.include?(association)
            codes_quoted_table_name = ActiveRecord::Base.connection.quote_table_name(
              "#{association}_codes_#{code_space_short_name}"
            )
            code_space_id = code_space_by_short_name(code_space_short_name)&.id
          end

          as = "#{association}_code_#{code_space_short_name}"
          if code_space_id
            klass_name = models.klass.reflections[association].klass.name
            request.joins("LEFT OUTER JOIN \"public\".codes #{codes_quoted_table_name} ON #{codes_quoted_table_name}.resource_type = '#{klass_name}' AND #{codes_quoted_table_name}.resource_id = #{association_quoted_table_name(association)}.id AND #{codes_quoted_table_name}.code_space_id = #{code_space_id}") # rubocop:disable Layout/LineLength
                   .select("#{codes_quoted_table_name}.value AS #{as}")
          else
            request.select("NULL AS #{as}")
          end
        end

        def select_association_registration_number(request, association)
          as = "#{association}_registration_number"
          if @included_associations.include?(association)
            request.select("#{association_quoted_table_name(association)}.registration_number AS #{as}")
          else
            request.select("NULL AS #{as}")
          end
        end

        def association_quoted_table_name(association)
          models.klass.reflections[association].klass.quoted_table_name
        end
      end

      CODE_SPACE_REGEXPS = {
        'line' => /%{line.code(?::([^}]*))?}/,
        'shape' => /%{shape.code:([^}]*)}/
      }.freeze
    end
  end
end
