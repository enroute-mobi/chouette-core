# frozen_string_literal: true

module Export
  # Manage all unique codes for a given Export::Scope
  class CodeProvider
    def initialize(export_scope)
      @export_scope = export_scope
    end

    attr_reader :export_scope

    # Returns unique code for the given model (StopArea, etc)
    def code(model)
      return unless model&.id

      send(collection_name(model.class)).code(model.id)
    end

    # TODO: should be generic (lines, companies, etc)
    def stop_areas
      @stop_areas ||= Model.new(export_scope.stop_areas, model_class: Chouette::StopArea).index
    end

    def point_of_interests
      @point_of_interests ||= Model.new(export_scope.point_of_interests, model_class: PointOfInterest::Base).index
    end

    def vehicle_journeys
      @vehicle_journeys ||= Model.new(export_scope.vehicle_journeys, model_class: Chouette::VehicleJourney).index
    end

    def collection_name(model_class)
      # Chouette::StopArea -> stop_areas
      model_class.model_name.plural
    end

    class Model
      def initialize(collection, model_class:)
        @collection = collection
        @model_class = model_class
        @codes = {}
      end

      attr_reader :collection, :model_class

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
        @codes & [model_id] if model_id
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
