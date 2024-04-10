# frozen_string_literal: true

module Export
  # Manage all unique codes for a given Export::Scope
  class CodeProvider
    def initialize(export_scope, code_space: nil)
      @export_scope = export_scope
      @code_space = code_space
    end

    attr_reader :export_scope, :code_space

    COLLECTIONS = %w[
      stop_areas point_of_interests vehicle_journeys lines companies entrances contracts
      vehicle_journey_at_stops journey_patterns routes time_tables fare_validities
      routing_constraint_zones networks fare_zones fare_products stop_points shapes
    ].freeze

    # Returns unique code for the given model (StopArea, etc)
    def code(model)
      return unless model&.id

      if collection = send(collection_name(model))
        collection.code(model.id)
      end
    end

    def codes(models)
      models.map { |model| code(model) }.compact
    end

    COLLECTIONS.each do |collection|
      define_method collection do
        if index = instance_variable_get("@#{collection}")
          return index
        end

        instance_variable_set("@#{collection}", Model.new(export_scope.send(collection)).index)
      end
    end

    def collection_name(model)
      begin
        model.model_name.collection
      rescue
        # When the model class is Chouette::StopPoint::Light::StopPoint...
        model.class.name.demodulize.underscore.pluralize
      end
    end

    class Model
      def initialize(collection, code_space = nil)
        @collection = collection
        @code_space = code_space

        @codes = {}
      end

      attr_reader :collection, :code_space

      def index
        @codes = Index.new(collection, code_space).codes

        self
      end

      class Index
        def initialize(collection, code_space = nil)
          @collection = collection
          @code_space = code_space
        end

        attr_reader :collection, :code_space

        def model_class
          @model_class ||= collection.model
        end
  
        ATTRIBUTES = %w[objectid uuid].freeze
        def attribute
          (ATTRIBUTES & model_class.column_names).first
        end
  
        def codes
          return indexes_with_codes if support_codes?

          indexes_without_codes
        end

        def time_table
          @time_table ||= collection.model_name.collection
        end

        def indexes_without_codes
          collection.pluck(:id, attribute).to_h
        end

        def indexes_with_codes
          @indexes_with_codes = {}

          collection
            .left_joins(:codes)
            .select(*select)
            .each { |model| fetch_code(model, @indexes_with_codes) }

          @indexes_with_codes
        end

        def fetch_code(model, indexes)
          if model.count <= 1 && model.code_value && model.code_space_id == code_space.id
            indexes[model.id] = model.code_value
          elsif indexes[model.id].blank?
            indexes[model.id] = model.send(attribute)
          end
        end

        def select
          [
            :id, attribute, "COUNT(#{time_table}.id) OVER (PARTITION BY codes.code_space_id, #{time_table}.id)",
            :stop_area_referential_id, 'codes.code_space_id AS code_space_id', 'codes.value AS code_value'
          ]
        end

        def support_codes?
          code_space.present? && collection.reflect_on_association(:codes).present?
        end
      end

      def register(model_id, as: value)
        @codes[model_id] = value
      end

      def code(model_id)
        @codes[model_id] if model_id
      end

      def codes(model_ids)
        model_ids.map { |model_id| code(model_id) }.compact
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
      def code(_model_or_id); end

      def codes(_models_or_ids)
        []
      end

      def method_missing(name, *arguments)
        return self if name.end_with?('s') && arguments.empty?

        super
      end
    end
  end
end
