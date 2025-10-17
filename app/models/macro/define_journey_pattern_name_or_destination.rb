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

      def model_attribute
        candidate_target_attributes.find_by(model_name: 'JourneyPattern', name: target_attribute)
      end

      def candidate_target_attributes
        Chouette::ModelAttribute.collection do
          # Chouette::JourneyPattern
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
          Updater.new(self, journey_pattern, target_attribute, target_format).update
        end
      end

      def journey_patterns
        @journey_patterns ||= Query.new(scope).journey_patterns_with_departure_and_arrival_names
      end

      protected

      def messages_options
        {
          resource_name_key: nil
        }
      end

      class Updater
        def initialize(macro_run, journey_pattern, attribute, format)
          @macro_run = macro_run
          @journey_pattern = journey_pattern
          @attribute = attribute
          @journey_pattern_name = journey_pattern.name
          @format = format
        end
        attr_reader :macro_run, :journey_pattern, :attribute, :journey_pattern_name, :format

        delegate :messages, to: :macro_run

        def update
          success = journey_pattern.update attribute => attribute_value

          messages.create(
            source: journey_pattern,
            journey_pattern_name: journey_pattern_name,
            attribute_value_after_change: attribute_value
          ) do |message|
            message.error! unless success
          end
        end

        def attribute_value
          @attribute_value ||= format.gsub('%{departure.name}', journey_pattern.departure_name)
                                     .gsub('%{arrival.name}', journey_pattern.arrival_name)
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
