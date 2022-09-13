# frozen_string_literal: true

describe Rack::CacheSettings do
  subject(:middleware) { Rack::CacheSettings.new(app) }
  let(:app) { ->(_env) { [200, {}, 'success'] } }

  describe 'call' do
    subject { Rack::Response[*middleware.call(env)] }

    let(:env) { Rack::MockRequest.env_for(path, method: :get) }

    %w[/packs/static/image.png /packs/css/application.css /packs/js/application.js].each do |path|
      context "when request path is #{path}" do
        let(:path) { path }

        it { is_expected.to have_header('Cache-Control') }
        it { is_expected.to have_header('Expires') }
      end
    end
  end

  describe '.match?' do
    subject { middleware.match? path }

    context 'when given path starts by /packs/' do
      let(:path) { '/packs/...' }
      it { is_expected.to be_truthy }
    end

    context 'when given path is /' do
      let(:path) { '/' }
      it { is_expected.to be_falsy }
    end
  end

  describe '.time_to_live' do
    subject { middleware.time_to_live }
    it { is_expected.to eq(1.year) }
  end

  describe '.cache_control' do
    subject { middleware.cache_control }
    it { is_expected.to eq('max-age=31556952, public') }
  end

  describe '.expires_at' do
    subject { middleware.expires_at }
    it { is_expected.to be_within(1.second).of(1.year.from_now) }
  end

  describe 'expires' do
    subject { middleware.expires }

    context 'when expires_at is 2030-01-01 12:00 +02' do
      let(:expires_at) { Time.parse '2030-01-01 12:00 +02' }
      before { allow(middleware).to receive(:expires_at).and_return(expires_at) }

      it { is_expected.to eq('Tue, 01 Jan 2030 10:00:00 -0000') }
    end
  end

  describe '.setup_cache' do
    let(:response) { Rack::Response.new }

    subject { middleware.setup_cache response }

    it { expect { subject }.to change { response.get_header('Cache-Control') }.to(middleware.cache_control) }

    it { expect { subject }.to change { response.get_header('Expires') }.to(middleware.expires) }
  end
end
