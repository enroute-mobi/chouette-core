module Support
  module JsonHelper
    def json_response_body
      JSON.parse(response.body)
    end
  end
end

RSpec.configure do | config |
  config.include Support::JsonHelper, type: :request
end
