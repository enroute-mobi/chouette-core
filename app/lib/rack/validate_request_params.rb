# frozen_string_literal: true

module Rack
  # Rejects requets with invalid characters (like null byte)
  class ValidateRequestParams
    INVALID_CHARACTERS = [
      "\u0000" # null bytes
    ].freeze

    def initialize(app)
      @app = app
    end

    def invalid_characters_regex
      @invalid_characters_regex ||= Regexp.union(INVALID_CHARACTERS)
    end

    def call(env)
      request = Rack::Request.new(env)

      has_invalid_character = request.params.values.any? do |value|
        value.match?(invalid_characters_regex) if value.respond_to?(:match)
      end

      if has_invalid_character
        # Stop execution and respond with the minimal amount of information
        return [400, {}, ['Bad Request']]
      end

      @app.call(env)
    end
  end
end
