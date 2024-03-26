# frozen_string_literal: true

module Export
  # Manage all unique codes for a given Export::Scope
  class CodeProvider
    def initialize(export_scope)
      @export_scope = export_scope
    end

    attr_reader :export_scope

    COLLECTIONS = %w[
      stop_areas point_of_interests vehicle_journeys lines companies
      entrances vehicle_journey_at_stops journey_patterns routes codes
      time_tables referential_codes routing_constraint_zones networks
      shapes fare_zones fare_products fare_validities contracts stop_points
    ].freeze

    # Returns unique code for the given model (StopArea, etc)
    def code(model)
      return unless model&.id

      if collection = send(collection_name(model.class))
        collection.code(model.id)
      end
    end

    COLLECTIONS.each do |collection|
      define_method collection do
        unless instance_variable_get("@#{collection}")
          instance_variable_set("@#{collection}", Model.new(export_scope.send(collection)).index)
        else
          instance_variable_set("@#{collection}", nil)
        end
      end
    end

    def collection_name(model_class)
      # Chouette::StopArea -> stop_areas
      model_class.model_name.plural
    end

    class Model
      def initialize(collection)
        @collection = collection

        @codes = {}
      end

      attr_reader :collection

      def model_class
        @model_class ||= collection.model
      end

      ATTRIBUTES = %w[objectid uuid].freeze
      def attribute
        (ATTRIBUTES & model_class.column_names).first
      end

      def index
        @codes = collection.pluck(:id, attribute).to_h

        self
      end

      def register(model_id, as: value)
        @codes[model_id] = value
      end

      def code(model_id)
        @codes[model_id] if model_id
      end
    end

    # Default implementation when a real Export::CodeProvider isn't provided
    #
    # Export::CodeProvider.null.code(..) => nil
    # Export::CodeProvider.null.stop_areas.code(..) => nil
    def self.null
      @null ||= Null.new
    end

    class Null
      def code(model_or_id); end

      def method_missing(name, *arguments)
        return self if name.end_with?('s') && arguments.empty?

        super
      end
    end
  end
end
