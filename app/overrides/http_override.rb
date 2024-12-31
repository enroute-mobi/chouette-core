module Net
  class HTTP
    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.0.0')
      # Add support for get_response(URI, headers) (provided by Ruby 3.0)
      def self.get_response(uri_or_host, path_or_headers = nil, port = nil, &block) # rubocop:disable Metrics/MethodLength
        if path_or_headers && !path_or_headers.is_a?(Hash)
          host = uri_or_host
          path = path_or_headers
          new(host, port || HTTP.default_port).start do |http|
            return http.request_get(path, &block)
          end
        else
          uri = uri_or_host
          headers = path_or_headers
          start(uri.hostname, uri.port,
                use_ssl: uri.scheme == 'https') do |http|
            return http.request_get(uri, headers, &block)
          end
        end
      end
    end
  end
end
