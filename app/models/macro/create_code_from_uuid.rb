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
        request = RequestBuilder.new(workgroup, models, code_space, format).run
        request.find_each do |model|
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
          if ::Regexp.last_match(1)
            model.send("line_code_#{::Regexp.last_match(1)}")
          else
            model.line_registration_number
          end
        end
      end

      class RequestBuilder
        def initialize(workgroup, models, code_space, format)
          @workgroup = workgroup
          @models = models
          @code_space = code_space
          @format = format
        end
        attr_reader :workgroup, :models, :code_space, :format

        def code_space_by_short_name(code_space_short_name)
          @code_spaces ||= workgroup.code_spaces.index_by(&:short_name)
          @code_spaces[code_space_short_name]
        end

        def run
          request = models
          request = without_code(request)
          request = preload_line_codes(request)
          request = select_all_model_columns(request)
          request
        end

        def without_code(request)
          request.without_code(code_space)
        end

        def preload_line_codes(request)
          return request unless format

          format.scan(CODE_SPACE_REGEXP) do
            request = include_lines(request)

            request = if ::Regexp.last_match(1)
                        include_and_select_line_code(request, ::Regexp.last_match(1))
                      else
                        select_line_registration_number(request)
                      end
          end

          request
        end

        def select_all_model_columns(request)
          request.select("#{models.klass.quoted_table_name}.*")
        end

        private

        def include_lines(request) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          if !@lines_included && models.klass == Chouette::Route
            @lines_included = true
            # TODO: should be simply request.left_joins(:line)
            # However, there is a bug with Rails where any call to #joins will be placed before any #left_joins and
            # since #left_joins does not accept raw SQL, we have to use #joins.
            # This may be fixed in future Rails versions.
            request.joins('LEFT OUTER JOIN "public"."lines" ON "public"."lines"."id" = "routes"."line_id"')
          elsif !@lines_included && models.klass == Chouette::JourneyPattern
            @lines_included = true
            # TODO: should be simply request.left_joins(route: :line)
            request.joins('LEFT OUTER JOIN "routes" ON "routes"."id" = "journey_patterns"."route_id"') \
                   .joins('LEFT OUTER JOIN "public"."lines" ON "public"."lines"."id" = "routes"."line_id"')
          elsif !@lines_included && models.klass == Chouette::VehicleJourney
            @lines_included = true
            # TODO: should be simply request.left_joins(route: :line)
            request.joins('LEFT OUTER JOIN "routes" ON "routes"."id" = "vehicle_journeys"."route_id"') \
                   .joins('LEFT OUTER JOIN "public"."lines" ON "public"."lines"."id" = "routes"."line_id"')
          else
            request
          end
        end

        def select_line_registration_number(request)
          if @lines_included
            request.select('lines.registration_number AS line_registration_number')
          else
            request.select('NULL AS line_registration_number')
          end
        end

        def include_and_select_line_code(request, code_space_short_name) # rubocop:disable Metrics/MethodLength
          if @lines_included
            @included_line_codes ||= Set.new
            return request if @included_line_codes.include?(code_space_short_name)

            quoted_table_name = ActiveRecord::Base.connection.quote_table_name("line_codes_#{code_space_short_name}")
            code_space_id = code_space_by_short_name(code_space_short_name)&.id

            @included_line_codes << code_space_short_name
          end

          if code_space_id
            request.joins("LEFT OUTER JOIN \"public\".codes #{quoted_table_name} ON #{quoted_table_name}.resource_type = 'Chouette::Line' AND #{quoted_table_name}.resource_id = lines.id AND #{quoted_table_name}.code_space_id = #{code_space_id}") \
                   .select("#{quoted_table_name}.value AS line_code_#{code_space_short_name}")
          else
            request.select("NULL AS line_code_#{code_space_short_name}")
          end
        end
      end

      CODE_SPACE_REGEXP = /%{line.code(?::([^}]*))?}/.freeze
    end
  end
end
