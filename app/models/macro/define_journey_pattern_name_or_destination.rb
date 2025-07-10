# frozen_string_literal: true

module Macro
  class DefineJourneyPatternNameOrDestination < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_attribute
        option :target_format

        validates :target_attribute, :target_format, presence: true
      end

      def journey_pattern_attribute
        candidate_journey_pattern_attributes.find_by(model_name: 'JourneyPattern', name: target_attribute)
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
          if new_name = defined_name(journey_pattern).presence
            journey_pattern_name = journey_pattern.name
            journey_pattern.update attribute_name => new_name

            create_message(journey_pattern, journey_pattern_name, new_name)
          end
        end
      end

      def create_message(journey_pattern, journey_pattern_name, new_name)
        attributes = {
          message_attributes: {
            journey_pattern_name: journey_pattern_name,
            new_name: new_name,
          },
          source: journey_pattern
        }

        macro_messages.create!(attributes)
      end

      def defined_name(journey_pattern)
        target_format.gsub('%{departure.name}', journey_pattern.departure_name)
                     .gsub('%{arrival.name}', journey_pattern.arrival_name)
      end

      def attribute_name
        @attribute_name ||= journey_pattern_attribute.name
      end

      def journey_patterns
        scope.journey_patterns.select(*selected_fields).from("(#{base_query.to_sql}) journey_patterns")
      end

      def selected_fields
        [
          'stop_area_names[1] AS departure_name',
          'stop_area_names[array_length(stop_area_names, 1)] AS arrival_name'
        ].concat(Chouette::JourneyPattern.column_names)
      end

      def base_query
        scope
          .journey_patterns
          .joins(:stop_areas)
          .group('journey_patterns.id')
          .select('journey_patterns.*', 'ARRAY_AGG(stop_areas.name ORDER BY stop_points.position) AS stop_area_names')
      end
    end
  end
end
