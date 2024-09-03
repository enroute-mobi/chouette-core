# frozen_string_literal: true

# Retrieve Address from a position
module ReverseGeocode
  # Provides ReverseGeocode instances according a given config
  class Config
    def initialize
      yield self if block_given?
    end

    def resolver_classes
      @resolver_classes ||= []
    end

    def batch
      ReverseGeocode::Batch.new.tap do |batch|
        batch.resolver_classes.concat resolver_classes
      end
    end
  end

  # Regroups positions to resolve their addresses
  class Batch
    def address(position, key: nil)
      item = Item.new(position)

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

    def each_address
      resolve

      items.each_value do |item|
        item.keys.each do |key| # rubocop:disable Style/HashEachMethods
          yield key, item.address
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

    def addresses
      enum_for(:each_address)
    end

    def resolver_classes
      @resolver_classes ||= []
    end
  end

  # Associates position and resolved address
  class Item
    attr_reader :position
    attr_accessor :address

    def initialize(position)
      @position = position
    end

    def cache_key
      @cache_key ||= [position.lat.round(6), position.lon.round(6)].join('-')
    end

    def keys
      @keys ||= Set.new
    end

    def resolved?
      address.present?
    end
  end

  module Resolver
    # Doesn't resolve addresses
    class Null
      def initialize(next_instance = nil); end

      def resolve(items); end
    end

    # Keeps in cache addresses created by another instance
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
          item.address = cache.read item.cache_key
        end
      end

      def write(items)
        items.select(&:resolved?).each do |item|
          Rails.logger.debug { "Write #{item.cache_key} in cache" }
          cache.write(item.cache_key, item.address, expires_in: time_to_live)
        end
      end
      mattr_accessor :time_to_live, default: 30.days

      def cache
        @cache ||= WithNamespace.new Rails.cache, 'reverse-geocode'
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

    # Uses TomTom Reverse Geocode API in batch mode to resolve addresses
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
          @items = items.reject(&:resolved?).map { |item| Item.new(item, radius: radius) }
        end

        mattr_accessor :radius, default: 30

        def resolve
          response_batch_items.each_with_index do |response_batch_item, index|
            item = ordered_items[index]
            item.response = response_batch_item
          end
        end

        def response_batch_items
          response['batchItems'] || []
        end

        def response
          @response ||=
            begin
              Rails.logger.info { "Invoke TomTom Batch API with #{items.count} reverseGeocode queries" }
              JSON.parse(Net::HTTP.post(self.class.uri, body, 'Content-Type' => 'application/json').body)
            end
        end

        mattr_accessor :api_key, default: Rails.application.secrets.tomtom_api_key
        def self.uri
          @uri ||= URI("https://api.tomtom.com/search/2/batch/sync.json?key=#{api_key}")
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
          { query: "/reverseGeocode/#{position.lat},#{position.lon}.json&#{options.to_query}" }
        end

        def response=(response)
          return unless response['statusCode'] == 200

          self.tomtom_address = response['response']['addresses'].first['address']
        end

        def tomtom_address=(tomtom_address)
          self.address_attributes = {
            house_number: tomtom_address['streetNumber'],
            street_name: tomtom_address['streetName'],
            post_code: tomtom_address['postalCode'],
            city_name: tomtom_address['municipality'],
            country_code: tomtom_address['countryCode'],
            house_number_and_street_name: tomtom_address['streetNameAndNumber']
          }
        end

        def address_attributes=(address_attributes)
          self.address = Address.new(address_attributes)
        end
      end
    end

    class FrenchBAN
      include Measurable

      def resolve(items)
        return if items.empty?

        Request.new(items).resolve
      end
      measure :resolve

      class Request
        attr_reader :items

        def initialize(items)
          @items = items.reject(&:resolved?).map { |item| Item.new(item) }
        end

        mattr_accessor :request_per_second, default: 30

        def self.url
          @url ||= 'https://api-adresse.data.gouv.fr/reverse/'
        end

        def resolve
          items.each_with_index do |item, index|
            sleep 1 if index > 0 && index % request_per_second == 0

            item.response = response(item.params)
          end
        end

        def response(params)
          @response ||=
            begin
              Rails.logger.info { "Invoke BAN" }
              Curl.get(self.class.url, params)
            end
        end

        class Item < SimpleDelegator
          attr_accessor :index

          def initialize(item)
            super item
          end

          def params
            { lon: position.lon, lat: position.lat }
          end

          def response=(response)
            return unless response.status == '200'

            if feature = JSON.parse(response.body)['features'].first
              self.french_ban_address = feature['properties']
            end
          end

          def french_ban_address=(french_ban_address)
            self.address_attributes = {
              house_number: french_ban_address['housenumber'],
              street_name: french_ban_address['street'],
              post_code: french_ban_address['postcode'],
              city_name: french_ban_address['city'],
              country_code: 'FR',
              house_number_and_street_name: [french_ban_address['housenumber'], french_ban_address['street']].join(' ')
            }
          end

          def address_attributes=(address_attributes)
            self.address = Address.new(address_attributes)
          end
        end
      end
    end
  end
end
