# frozen_string_literal: true

module Import
  # Experimental version
  module Lookup
    def self.default(import)
      Default.new import
    end

    def self.referential(import)
      Referential.new import
    end

    class Default
      def initialize(import)
        @import = import
      end

      def stop_areas
        @stop_areas ||= ExternalCollection.new(internal_stop_areas)
      end

      def lines
        @lines ||= ExternalCollection.new(internal_lines)
      end

      def companies
        @companies ||= ExternalCollection.new(internal_companies)
      end

      def booking_arrangements
        @booking_arrangements ||= ExternalCollection.new(internal_booking_arrangements)
      end

      def shapes
        @shapes ||= ExternalCollection.new(internal_shapes)
      end

      # Very basic mechanism
      def on_response(on:, &block)
        on_collection = ExternalCollection.new(send("internal_#{on}"), on_response: block)
        override_collections = collections.merge(on => on_collection)

        Composite.new(**override_collections)
      end

      protected

      def collections
        {
          stop_areas: stop_areas,
          lines: lines,
          companies: companies,
          shapes: shapes,
          booking_arrangements: booking_arrangements
        }
      end

      private

      attr_accessor :import

      delegate :stop_area_provider, :line_provider, :shape_provider, :code_space, to: :import
      delegate :stop_area_referential, to: :stop_area_provider
      delegate :line_referential, to: :line_provider

      def internal_stop_areas
        @internal_stop_areas ||=
          Collection.new
                    .add(finder_class.new(stop_area_provider.stop_areas, source: :provider))
                    .add(finder_class.new(stop_area_referential.stop_areas, source: :workgroup))
      end

      def internal_lines
        @internal_lines ||=
          Collection.new
                    .add(finder_class.new(line_provider.lines, source: :provider))
                    .add(finder_class.new(line_referential.lines, source: :workgroup))
      end

      def internal_companies
        @internal_companies ||=
          Collection.new
                    .add(finder_class.new(line_provider.companies, source: :provider))
                    .add(finder_class.new(line_referential.companies, source: :workgroup))
      end

      def internal_booking_arrangements
        @internal_booking_arrangements ||= begin
          params = { source: :provider }
          booking_arrangement_finder_class = if import.override_internal_identifiers?
            Finder::Objectid
          else
            params.merge!(code_space: code_space)
            Finder::Code
          end

          Collection.new.add(booking_arrangement_finder_class.new(line_provider.booking_arrangements, **params))
        end
      end

      def internal_shapes
        @internal_shapes ||=
          Collection.new
                    .add(Finder::Code.new(shape_provider.shapes, code_space: code_space, source: :provider))
      end

      def finder_class
        import.override_internal_identifiers? ? Finder::Objectid : Finder::RegistrationNumber
      end
    end

    class Referential < Default
      def time_tables
        @time_tables ||= ExternalCollection.new(internal_time_tables)
      end

      protected

      delegate :referential, to: :import

      def collections
        super.merge(time_tables: time_tables)
      end

      private

      def internal_time_tables
        @internal_time_tables ||= Collection.new.add(Finder::Code.new(referential.time_tables, code_space: code_space, source: :referential))
      end
    end

    # Returns a Lookup which uses the given (External) Collections
    class Composite
      def initialize(stop_areas:, lines:, companies:, shapes:, booking_arrangements:)
        @stop_areas = stop_areas
        @lines = lines
        @companies = companies
        @shapes = shapes
        @booking_arrangements = booking_arrangements
      end

      attr_reader :stop_areas, :lines, :companies, :shapes, :booking_arrangements
    end

    # Returns identifier or model instead of internal Response
    class ExternalCollection
      def initialize(internal_collection, on_response: nil)
        @internal_collection = internal_collection
        @callback = on_response
      end

      # Returns identifier associated to the given code (or nil).
      # Additionnal arguments are used by on_response handler
      def find_id(code, **arguments)
        return nil if code.blank?

        response = internal_collection.find_id(code)
        on_response response, **arguments
        response.model_id
      end

      # Returns model associated to the given code (or nil).
      # Additionnal arguments are used by on_response handler
      def find(code, **arguments)
        return nil if code.blank?

        response = internal_collection.find(code)
        on_response response, **arguments
        response.model
      end

      # Returns all (uniq) identifiers associated to given codes
      def find_ids(*codes)
        codes = codes.flatten.compact.uniq
        codes.map { |code| find_id code }.compact.uniq
      end

      private

      attr_reader :internal_collection, :callback

      def on_response(response, **arguments)
        callback&.call response, arguments
      end
    end

    class Collection
      def finders
        @finders ||= []
      end

      def add(finder)
        finders << finder
        self
      end

      def cache
        @cache ||= Cache.new
      end

      def find_id(code, **_arguments)
        cache.fetch_id(code) do
          finders.lazy.map do |finder|
            id = finder.find_id(code)
            Response.new(code: code, model_id: id, source: finder.source) if id
          end.find(&:present?)
        end
      end

      def find(code, **_arguments)
        cache.fetch_model(code) do
          finders.lazy.map do |finder|
            model = finder.find(code)
            Response.new(code: code, model: model, source: finder.source) if model
          end.find(&:present?)
        end
      end
    end

    class Response
      attr_accessor :code, :model, :model_id, :source

      def initialize(code:, source:, model_id: nil, model: nil)
        @code = code
        @source = source
        @model_id = model_id
        @model = model
      end
    end

    class Cache
      def by_identifiers
        @by_identifiers ||= {}
      end

      def by_models
        @by_models ||= {}
      end

      def fetch_id(code, &block)
        response = by_identifiers[code]
        return response if response || !block_given?

        response = block.call(code)
        response ||= Response.new(code: code, model_id: nil, source: :none)

        by_identifiers[code] = response
        response
      end

      def fetch_model(code, &block)
        response = by_models[code]
        return response if response || !block_given?

        response = block.call(code)
        response ||= Response.new(code: code, model: nil, source: :none)

        by_models[code] = response
        response
      end
    end

    module Finder
      class Base
        def initialize(scope, source:)
          @scope = scope
          @source = source
        end

        attr_accessor :scope, :source

        def find_id(code)
          by_code(code).select(:id).first&.id
        end

        def find(code)
          by_code(code).first
        end
      end

      class Objectid < Base
        private

        def by_code(code)
          scope.where(objectid: code)
        end
      end

      class RegistrationNumber < Base
        private

        def by_code(code)
          scope.where(registration_number: code)
        end
      end

      class Code < Base
        def initialize(scope, code_space:, source:)
          super scope, source: source
          @code_space = code_space
        end

        attr_accessor :code_space

        private

        def by_code(code)
          scope.by_code(code_space, code)
        end
      end
    end
  end
end
