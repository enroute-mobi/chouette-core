# frozen_string_literal: true

RSpec.describe Users::UnlocksController, type: :controller do
  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe '#new' do
    before { get :new }

    it { expect(response).to have_http_status(:not_found) }
  end

  describe '#create' do
    before { post :create }

    it { expect(response).to have_http_status(:not_found) }
  end

  describe '#show' do
    before { get :show }

    it { expect(response).to have_http_status(:not_found) }
  end
end
