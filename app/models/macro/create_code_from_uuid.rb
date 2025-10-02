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
        request = RequestBuilder.new(workgroup, models, code_space, format).run
        request.find_each do |model|
          code_value = target.value(model)
          code = model.codes.create(code_space: code_space, value: code_value)
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

        attributes[:macro_run_id] = self.id
        Macro::Message.create!(attributes)
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

        # TODO: This could actually be something simple like srequest.left_joins(:line). This would give:
        #   request.left_joins(:lines).joins('LEFT OUTER JOINS public.codes ON...').
        # However, there is a weird behavior in Rails where any call to #joins will be placed before any #left_joins.
        # So the generated SQL will join the codes first and then the lines despite the JOIN on codes needing the lines
        # first. One solution could be something like:
        #   request.left_joins(:lines).left_joins('LEFT OUTER JOINS public.codes ON...')
        # But #left_joins only accepts association names, not row SQL. Only #joins accepts raw SQL.
        # Therefore, we have to use #joins everywhere using the raw SQL to have a LEFT OUTER JOIN instead of a JOIN.
        # This may be fixed in future Rails versions.
        JOINS = {
          'Chouette::Route' => {
            # TODO: should be simply request.left_joins(:line)
            line: ['LEFT OUTER JOIN "public"."lines" ON "public"."lines"."id" = "routes"."line_id"']
          },
          'Chouette::JourneyPattern' => {
            # TODO: should be simply request.left_joins(route: :line)
            line: [
              'LEFT OUTER JOIN "routes" ON "routes"."id" = "journey_patterns"."route_id"',
              'LEFT OUTER JOIN "public"."lines" ON "public"."lines"."id" = "routes"."line_id"'
            ],
            # TODO: should be simply request.left_joins(:shape)
            shape: [
              'LEFT OUTER JOIN "public"."shapes" ON "public"."shapes"."id" = "journey_patterns"."shape_id"'
            ]
          },
          'Chouette::VehicleJourney' => {
            # TODO: should be simply request.left_joins(route: :line)
            line: [
              'LEFT OUTER JOIN "routes" ON "routes"."id" = "vehicle_journeys"."route_id"',
              'LEFT OUTER JOIN "public"."lines" ON "public"."lines"."id" = "routes"."line_id"'
            ]
          }
        }

        def include_association(request, association)
          return request if @included_associations.include?(association)

          joins = JOINS.key?(models.klass.name) && JOINS[models.klass.name][association]
          return request unless joins

          @included_associations << association
          request.joins(*joins)
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
            klass_name = models.klass.reflections[association.to_s].klass.name
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
          models.klass.reflections[association.to_s].klass.quoted_table_name
        end
      end

      CODE_SPACE_REGEXPS = {
        line: /%{line.code(?::([^}]*))?}/,
        shape: /%{shape.code:([^}]*)}/
      }.freeze
    end
  end
end
