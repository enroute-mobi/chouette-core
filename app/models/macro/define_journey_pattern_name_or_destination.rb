# frozen_string_literal: true

module Macro
  class DefineJourneyPatternNameOrDestination < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_attribute
        option :target_format

        enumerize :target_attribute, in: %w[name published_name]
        validates :target_attribute, :target_format, presence: true
      end

      def candidate_journey_pattern_attributes
        Chouette::ModelAttribute.collection do
          select Chouette::JourneyPattern, :name
          select Chouette::JourneyPattern, :published_name
        end
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        journey_patterns.find_each do |journey_pattern|
          Updater.new(journey_pattern, target_attribute, target_format, macro_messages).update
        end
      end

      def journey_patterns
        @journey_patterns ||= Query.new(scope).journey_patterns_with_departure_and_arrival_names
      end

      class Updater
        def initialize(journey_pattern, attribute, format, messages = nil)
          @journey_pattern = journey_pattern
          @attribute = attribute
          @messages = messages
          @journey_pattern_name = journey_pattern.name
          @format = format
        end
        attr_reader :journey_pattern, :messages, :attribute, :journey_pattern_name, :format

        def update
          if journey_pattern.update attribute => attribute_value
            create_message
          else
            create_message criticity: 'error', message_key: 'error'
          end
        end

        def attribute_value
          @attribute_value ||= format.gsub('%{departure.name}', journey_pattern.departure_name)
                                     .gsub('%{arrival.name}', journey_pattern.arrival_name)
        end

        def create_message(attributes = {})
          return unless messages

          attributes.merge!(
            message_attributes: {
              journey_pattern_name: journey_pattern_name,
              attribute_value_after_change: attribute_value
            },
            source: journey_pattern
          )
          messages.create!(attributes)
        end
      end      

      class Query
        def initialize(scope)
          @scope = scope
        end
        attr_reader :scope

        def journey_patterns_with_departure_and_arrival_names
          scope.journey_patterns.select(*selected_fields).from("(#{base_query.to_sql}) journey_patterns")
        end

        def selected_fields
          [
            'stop_area_names[1] AS departure_name',
            'stop_area_names[array_length(stop_area_names, 1)] AS arrival_name'
          ].concat(journey_patterns.column_names)
        end

        def base_query
          journey_patterns
            .joins(:stop_areas)
            .group('journey_patterns.id')
            .select('journey_patterns.*', 'ARRAY_AGG(stop_areas.name ORDER BY stop_points.position) AS stop_area_names')
        end

        def journey_patterns
          @journey_patterns ||= scope.journey_patterns
        end
      end
    end
  end
end
