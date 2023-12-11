# frozen_string_literal: true

RSpec.describe Api::V1::PublicationApi::BaseController, type: :controller do
  controller do
    def show
      workgroup
      render plain: 'ok'
    end
  end

  before { routes.draw { get 'show' => 'api/v1/publication_api/base#show' } }

  describe 'publication_api' do
    context 'when a PublicationApi matches the given slug' do
      let(:context) { Chouette.create { publication_api } }
      let(:publication_api) { context.publication_api }

      before { get :show, params: { slug: publication_api.slug } }

      it 'assigns @publication_api with the PublicationApi' do
        expect(assigns(:publication_api)).to eq(publication_api)
      end

      it { expect(response).to have_http_status(:ok) }
    end

    context 'when no PublicationApi matches the given slug' do
      before { bypass_rescue }

      it do
        expect { get :show, params: { slug: 'dummy' } }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'authenticate' do
    let(:context) { Chouette.create { publication_api } }
    context 'when PublicationApi is public' do
      let(:publication_api) { context.publication_api }

      before { get :show, params: { slug: publication_api.slug } }
      it { expect(response).to have_http_status(:ok) }
    end

    context 'when PublicationApi is private' do
      let(:context) { Chouette.create { publication_api public: false } }
      let(:publication_api) { context.publication_api }

      def encode_credentials(token)
        ActionController::HttpAuthentication::Token.encode_credentials(token)
      end

      before do
        request.headers['Authorization'] = authorization_header
        get :show, params: { slug: publication_api.slug }
      end

      context 'without authentication header' do
        let(:authorization_header) { nil }
        it { expect(response).to have_http_status(:unauthorized) }
      end

      context 'with a wrong authentication header' do
        let(:authorization_header) { encode_credentials 'token' }
        it { expect(response).to have_http_status(:unauthorized) }
      end

      context 'with one of the API key tokens' do
        let(:token) { publication_api.api_keys.first.token }
        let(:authorization_header) { encode_credentials token }
        it { expect(response).to have_http_status(:ok) }
      end
    end
  end

  describe 'workgroup' do
    let(:context) { Chouette.create { publication_api } }
    let(:publication_api) { context.publication_api }
    let(:workgroup) { publication_api.workgroup }

    before { get :show, params: { slug: publication_api.slug } }

    it "assigns @workgroup with the PublicationApi's Workgroup" do
      expect(assigns(:workgroup)).to eq(workgroup)
    end
  end

  describe '#published_referential' do
    subject { controller.send :published_referential }

    let(:referential) { double('referential') }
    before do
      workgroup = double(output: double(current: referential))
      allow(controller).to receive(:workgroup).and_return(workgroup)
    end

    it { is_expected.to eq(referential) }
  end
end
