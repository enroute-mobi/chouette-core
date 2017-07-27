module Support
  module Webmock
    module Helpers
      def stub_headers(*args)
        {headers: make_headers(*args)}
      end

      def make_headers(headers={}, authorization_token:)
        headers.merge('Authorization' => "Token token=#{authorization_token.inspect}")
      end
    end
  end
end

RSpec.configure do | conf |
  conf.include Support::Webmock::Helpers, type: :model
  conf.include Support::Webmock::Helpers, type: :worker
end
