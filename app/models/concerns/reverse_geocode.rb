module ReverseGeocode
  class TomTom
    def address(position)
      Request.new(position).address
    end

    class Request
      def initialize(position)
        @position = position
      end
      attr_accessor :position

      def address
        begin
          response = JSON.parse(open(url).read)
          response['addresses'].first['address'].tap do |tomtom_address|
            return Address.new(
              tomtom_address['routeNumbers'].join(' '),
              tomtom_address['streetName'],
              tomtom_address['postalCode'],
              tomtom_address['municipality'],
              tomtom_address['countryCode']
            )
          end
        rescue => e
          Chouette::Safe.capture "Something goes wrong in TomTom API", e
          return nil
        end
      end

      private

      def url
        [ 
          "https://api.tomtom.com/search/2/reverseGeocode/#{position.lat},#{position.lon}.json?returnSpeedLimit=false&",
          "radius=20&returnRoadUse=false&allowFreeformNewLine=false&returnMatchType=false&view=Unified&key=#{api_key}"
        ].join
      end

      def api_key
        if Rails.env.test? || Rails.env.development?
          Rails.application.secrets.tomtom_api_key_interne
        else
          Rails.application.secrets.tomtom_api_key
        end
      end

    end
  end

  class Cache
    def initialize(next_instance)
      @next_instance = next_instance
    end
    attr_reader :next_instance

    def address(position)
      Rails.cache.fetch(rounded_point(position)) do
        next_instance.address(position)
      end
    end

    private

    def rounded_point(position)
      "#{position.lat.round(6)},#{position.lon.round(6)}"
    end
  end

  class Null
    def address(*)
    end
  end
end