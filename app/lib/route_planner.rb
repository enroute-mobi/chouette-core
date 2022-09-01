# frozen_string_literal: true

# Create Shape from given points
module RoutePlanner
  # Regroups waypoints to resolve their shapes
  class Batch
    def shape(points, key: nil)
      item = Item.new(points)

      # Reuse an already defined Item
      item = (items[item.cache_key] ||= item)
      raise "Can't manage more than #{maximum_item_count} in a single batch" if items.size > maximum_item_count

      item.keys << key if key

      item
    end

    mattr_accessor :maximum_item_count, default: 100

    def items
      @items ||= {}
    end

    def each_shape
      resolve

      items.each_value do |item|
        item.keys.each do |key| # rubocop:disable Style/HashEachMethods
          yield key, item.shape
        end
      end
    end

    def resolve
      return if @resolved

      @resolved = true
      resolver.resolve items.values.reject(&:resolved?)
    end

    def resolver
      @resolver ||= resolver_classes.inject(nil) do |previous, resolver_class|
        # Invoke without previous if nil
        resolver_class.new(*[previous].compact)
      end || Resolver::Null.new
    end

    def shapes
      enum_for(:each_shape)
    end

    def resolver_classes
      @resolver_classes ||= []
    end
  end

  # Associates waypoints and resolved shape
  class Item
    attr_reader :points
    attr_accessor :shape

    def initialize(points)
      @points = points
    end

    def cache_key
      @cache_key ||= rounded_points
    end

    def keys
      @keys ||= Set.new
    end

    def resolved?
      shape.present?
    end

    private

    def rounded_points
      points.map { |point| "#{point.latitude.round(6)},#{point.longitude.round(6)}" }.join(':')
    end
  end

  module Resolver
    # Doesn't resolve shapes
    class Null
      def initialize(next_instance = nil); end

      def resolve(items); end
    end

    # Keeps in cache shapes created by another instance
    class Cache
      include Measurable
      def initialize(next_instance)
        @next_instance = next_instance
      end

      def resolve(items)
        read items
        items = items.reject(&:resolved?)

        @next_instance.resolve(items)
        write items
      end
      measure :resolve

      def read(items)
        items.reject(&:resolved?).each do |item|
          Rails.logger.debug { "Read #{item.cache_key} in cache" }
          item.shape = cache.read item.cache_key
        end
      end

      def write(items)
        items.select(&:resolved?).each do |item|
          Rails.logger.debug { "Write #{item.cache_key} in cache" }
          cache.write(item.cache_key, item.shape, expires_in: time_to_live)
        end
      end
      mattr_accessor :time_to_live, default: 7.days

      def cache
        @cache ||= WithNamespace.new Rails.cache, 'route_planner'
      end

      # Adds a namespace to read/write method invocations
      class WithNamespace
        def initialize(cache, namespace)
          @cache = cache
          @namespace = namespace
        end
        attr_reader :cache, :namespace

        def read(name, options = {})
          cache.read name, with_namespace(options)
        end

        def write(name, value, options = {})
          cache.write name, value, with_namespace(options)
        end

        def with_namespace(options)
          (options || {}).merge(namespace: namespace)
        end
      end
    end

    # Uses TomTom Calculate Route API in batch mode to resolve shapes
    class TomTom
      include Measurable

      def resolve(items)
        return if items.empty?

        Request.new(items).resolve
      end
      measure :resolve

      # Performs the TomTom API request
      class Request
        attr_reader :items

        def initialize(items)
          @items = items.reject(&:resolved?).map do |item|
            Item.new(item, { routeType: 'fastest', traffic: false, travelMode: 'bus' })
          end
        end

        def resolve
          response_batch_items.each_with_index do |response_batch_item, index|
            item = ordered_items[index]
            item.response = response_batch_item
          end
        end

        def response_batch_items
          response['batchItems']
        end

        def response
          @response ||=
            begin
              Rails.logger.debug { "Invoke TomTom Batch API with #{items.count} calculateRoute queries" }
              JSON.parse(Net::HTTP.post(self.class.uri, body, 'Content-Type' => 'application/json').body)
            end
        end

        mattr_accessor :api_key, default: Rails.application.secrets.tomtom_api_key
        def self.uri
          @uri ||= URI("https://api.tomtom.com/routing/1/batch/sync/json?key=#{api_key}")
        end

        def body
          { batchItems: request_batch_items }.to_json
        end

        def request_batch_items
          items.map.with_index do |item, index|
            item.index = index
            item.request
          end
        end

        def ordered_items
          @ordered_items ||= items.sort_by(&:index)
        end
      end

      # Adds specific attributes to manage the item in TomTom API request/response
      class Item < SimpleDelegator
        attr_accessor :index
        attr_reader :options

        def initialize(item, options = {})
          super item
          @options = options
        end

        def request
          { query: "/calculateRoute/#{locations}/json?#{options.to_query}" }
        end

        def response=(response)
          return unless response['statusCode'] == 200

          self.tomtom_shape = tomtom_points(response['response'])
        end

        def tomtom_shape=(tomtom_points)
          self.shape = rgeo_factory.line_string(tomtom_points)
        end

        def tomtom_points(response)
          response['routes'].first['legs'].flat_map do |leg|
            leg['points'].flat_map do |point|
              longitude, latitude = point.values_at('longitude', 'latitude')
              rgeo_factory.point(longitude, latitude)
            end
          end
        end

        mattr_reader :rgeo_factory, default: RGeo::Geos.factory(srid: 4326)

        def locations
          points.map { |point| "#{point.latitude},#{point.longitude}" }.join(':')
        end
      end
    end
  end
end
