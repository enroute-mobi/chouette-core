# frozen_string_literal: true

module Rack
  # Adds cache headers to the Rack response
  class CacheSettings
    def initialize(app)
      @app = app
    end

    def call(env)
      response = Rack::Response[*@app.call(env)]
      return response.finish unless response.successful?

      path = env['PATH_INFO']
      setup_cache response if match?(path)

      response.finish
    end

    def match?(path)
      path.start_with? '/packs/'
    end

    def time_to_live
      @time_to_live ||= 1.year
    end

    def cache_control
      @cache_control ||= "max-age=#{time_to_live.to_i}, public"
    end

    def expires_at
      now + time_to_live
    end

    def expires
      expires_at.utc.rfc2822
    end

    def setup_cache(response)
      response.set_header 'Cache-Control', cache_control
      response.set_header 'Expires', expires
    end

    def now
      Time.zone.now
    end
  end
end
