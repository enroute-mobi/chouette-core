# frozen_string_literal: true

module Control
  class PresenceAssociatedModel < Control::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :collection
        option :minimum
        option :maximum

        enumerize :target_model, in: %w[Line StopArea Route JourneyPattern VehicleJourney TimeTable]
        validates :target_model, :collection, presence: true
        validates :minimum, :maximum, numericality: { only_integer: true, allow_blank: true }
      end

      def candidate_collections # rubocop:disable Metrics/MethodLength
        Chouette::ModelAttribute.collection do
          select Chouette::StopArea, :routes
          select Chouette::StopArea, :lines
          select Chouette::StopArea, :fare_zones
          # select Chouette::StopArea, :entrances
          # select Chouette::StopArea, :connection_links

          select Chouette::Line, :routes
          # select Chouette::Line, :secondary_companies

          select Chouette::Route, :stop_points
          select Chouette::Route, :journey_patterns
          select Chouette::Route, :vehicle_journeys

          select Chouette::JourneyPattern, :stop_points
          select Chouette::JourneyPattern, :vehicle_journeys

          select Chouette::VehicleJourney, :time_tables

          select Chouette::TimeTable, :periods
          select Chouette::TimeTable, :dates
        end
      end

      def collection_attribute
        candidate_collections.find_by(model_name: target_model, name: collection)
      end
    end
    include Options

    validate :minimum_or_maximum

    private

    def minimum_or_maximum
      return if minimum.present? || maximum.present?

      errors.add(:minimum, :invalid)
    end

    class Run < Control::Base::Run
      include Options

      def run
        faulty_models.find_each do |model|
          count = faulty_counts[model.id]
          human_name = model.try(:name) || model.try(:get_object)&.short_id

          control_messages.create(message_attributes: { name: human_name, count: count },
                                  criticity: criticity,
                                  source: model,
                                  message_key: :presence_associated_model)
        end
      end

      def context_collection
        case [target_model, collection]
        when %w[JourneyPattern stop_points]
          'journey_pattern_stop_points'
        when %w[TimeTable periods]
          'time_table_periods'
        when %w[TimeTable dates]
          'time_table_dates'
        else
          collection
        end
      end

      # Retrieve models where a faulty count is dedicated
      def faulty_models
        models.where(id: faulty_counts.keys)
      end

      # Retrieve model identifier (only) associated to a faulty county
      # Ex: { <route id 1> => <stop point count>, <route id 2> => <stop point count> }
      def faulty_counts
        @faulty_counts ||= models.left_outer_joins(collection.to_sym) \
                                 .group("#{models.klass.quoted_table_name}.id") \
                                 .having(condition, { minimum: minimum, maximum: maximum }) \
                                 .count(count_arg)
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize.to_sym
      end

      def models
        @models ||= context.send(model_collection)
      end

      def condition
        if minimum.present? && maximum.present?
          "count(#{count_arg}) < :minimum or count(#{count_arg}) > :maximum"
        elsif minimum.present?
          "count(#{count_arg}) < :minimum"
        else
          "count(#{count_arg}) > :maximum"
        end
      end

      def count_arg
        @count_arg ||= "DISTINCT #{models.klass.reflections[collection].klass.quoted_table_name}.id"
      end
    end
  end
end
