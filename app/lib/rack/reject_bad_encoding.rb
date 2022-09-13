# frozen_string_literal: true

module Rack
  # Rejects requests if a bad encoding is detected
  class RejectBadEncoding
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        Rack::Utils.parse_nested_query(env['QUERY_STRING'].to_s)
      rescue Rack::Utils::InvalidParameterError
        return [400, {}, ['Bad Request']]
      end

      @app.call(env)
    end
  end
end
