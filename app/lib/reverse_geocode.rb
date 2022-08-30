# frozen_string_literal: true

# Retrieve Address from a position
module ReverseGeocode
  # Use TomTom Routing API to find address
  class TomTom
    include Measurable

    def address(position)
      Request.new(position).address
    end
    measure :address

    # Performs a Request to the TomTom Reverse Geocode API
    class Request < ::TomTom::Request
      def initialize(position)
        super()
        @position = position
      end
      attr_reader :position

      def address
        Rails.logger.debug { "Invoke TomTom Reverse Geocode API for #{position}" }
        Address.new(address_attributes)
      rescue StandardError => e
        Chouette::Safe.capture "Can't read TomTom Reverse Geocode API response", e
        nil
      end

      def tomtom_address
        @tomtom_address ||= response['addresses'].first['address']
      end

      def address_attributes
        {
          house_number: tomtom_address['routeNumbers'].join(' '),
          street_name: tomtom_address['streetName'],
          post_code: tomtom_address['postalCode'],
          city_name: tomtom_address['municipality'],
          country_code: tomtom_address['countryCode']
        }
      end

      private

      def url
        [
          "https://api.tomtom.com/search/2/reverseGeocode/#{position.lat},#{position.lon}.json?returnSpeedLimit=false&",
          "radius=20&returnRoadUse=false&allowFreeformNewLine=false&returnMatchType=false&view=Unified&key=#{api_key}"
        ].join
      end
    end

    class Batch < ::TomTom::Request
      def initialize(positions)
        @positions = positions
      end
      attr_reader :positions

      def url
        "https://api.tomtom.com/search/2/batch/sync.json?key=#{api_key}"
      end

      def body
        { batchItems: batch_items }.to_json
      end

      def batch_items
        positions.map do |position|
          { query: "/reverseGeocode/#{position.lat},#{position.lon}.json" }
        end
      end

      def response
        @response ||= JSON.parse(call_api(url, { type: 'POST', body: body }))
      end
    end
  end

  # Keep in cache addresses created by another instance
  class Cache
    include Measurable

    def initialize(next_instance)
      @next_instance = next_instance
    end
    attr_reader :next_instance

    def address(position)
      Rails.cache.fetch(rounded_point(position), skip_nil: true, expires_in: time_to_live) do
        next_instance.address(position)
      end
    end
    measure :address

    mattr_accessor :time_to_live, default: 7.days

    private

    def rounded_point(position)
      [position.lat.round(6), position.lon.round(6)]
    end
  end

  # Returns nil
  class Null
    def address(*); end
  end
end
