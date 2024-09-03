# frozen_string_literal: true

module Macro
  class DefineRouteName < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_attribute
        option :target_format

        enumerize :target_attribute, in: %w[name published_name]
        validates :target_attribute, :target_format, presence: true
      end

      def candidate_target_attributes
        Chouette::ModelAttribute.collection do
          # Chouette::Route
          select Chouette::Route, :name
          select Chouette::Route, :published_name
        end
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        routes.find_each do |route|
          Updater.new(route, target_attribute, target_format, macro_messages).update
        end
      end

      def routes
        @routes ||= Query.new(scope).routes_with_departure_and_arrival_names
      end

      class Updater
        def initialize(route, attribute, format, messages = nil)
          @route = route
          @attribute = attribute
          @messages = messages
          @name_before_change = route.name
          @format = format
        end
        attr_reader :route, :messages, :attribute, :name_before_change, :format

        def update
          if route.update attribute => attribute_value
            create_message
          else
            create_message criticity: 'error', message_key: 'error'
          end
        end

        def attribute_value
          @attribute_value ||= format
                               .gsub('%{direction}', route.wayback.text)
                               .gsub('%{departure.name}', route.departure_name)
                               .gsub('%{arrival.name}', route.arrival_name)
        end

        def create_message(attributes = {})
          return unless messages

          attributes.merge!(
            message_attributes: {
              name_before_change: name_before_change,
              attribute_value_after_change: attribute_value
            },
            source: route
          )
          messages.create!(attributes)
        end
      end

      class Query
        def initialize(scope)
          @scope = scope
        end
        attr_reader :scope

        def routes_with_departure_and_arrival_names
          sql = routes
                .select(
                  route_column_names,
                  'stop_area_names[1] AS departure_name',
                  'stop_area_names[2] AS arrival_name'
                )
                .from("(#{routes_with_raw_departure_and_arrival_names.to_sql}) AS routes")
                .to_sql

          routes.select('*').from("(#{sql}) AS routes")
        end

        def routes_with_raw_departure_and_arrival_names
          routes
            .select(route_column_names, stop_area_names)
            .from(base_query)
            .where('departure OR arrival')
            .group(route_column_names)
        end

        def route_column_names
          @route_column_names ||= routes.column_names.join(', ')
        end

        def stop_area_names
          'ARRAY_AGG(routes.stop_area_name) AS stop_area_names'
        end

        def base_query
          "(#{routes.joins(stop_points: :stop_area).select(base_select).to_sql}) AS routes"
        end

        def base_select
          <<~SQL
            routes.*,
            stop_areas.name AS stop_area_name,
            (LAG(stop_areas.name, 1) OVER (PARTITION BY routes.id ORDER BY stop_points.position)) IS NULL AS departure,
            (LEAD(stop_areas.name, 1) OVER (PARTITION BY routes.id ORDER BY stop_points.position)) IS NULL arrival
          SQL
        end

        def routes
          @routes ||= scope.routes
        end
      end
    end
  end
end
