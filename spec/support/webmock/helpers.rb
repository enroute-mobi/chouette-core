WebMock.disable_net_connect!(allow: 'api.codacy.com')

module Support
  module Webmock
    module Helpers
      def stub_headers(*args)
        {headers: make_headers(*args)}
      end

      def make_headers(headers={}, authorization_token:)
        headers.merge('Authorization' => "Token token=#{authorization_token.inspect}")
      end

      def with_stubbed_request( method, uri, &blk )
        stub_request(method, uri).tap(&blk)
      end

    end
  end
end

RSpec.configure do | conf |
  conf.include Support::Webmock::Helpers, type: :model
  conf.include Support::Webmock::Helpers, type: :worker
end
