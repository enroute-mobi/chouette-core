# frozen_string_literal: true

describe Rack::ValidateRequestParams do
  include Rack::Test::Methods
  let(:app) { ChouetteIhm::Application }

  # We need a page without redirection
  let(:path) { '/users/sign_up' }

  subject { last_response }

  context 'with invalid characters' do
    let(:null_byte) { "\u0000" }

    before { get path, test: "I am #{null_byte} bad" }
    it { is_expected.to be_bad_request }
  end

  context 'without invalid characters' do
    before { get path, lang: 'fr' }

    it { is_expected.to be_ok }
  end

  context 'without parameters' do
    before { get path }

    it { is_expected.to be_ok }
  end
end
