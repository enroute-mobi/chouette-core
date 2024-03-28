# frozen_string_literal: true

RSpec.describe FareZonesController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          fare_provider :fare_provider
          fare_zone :fare_zone
        end
        workbench(organisation: organisation) do
          fare_provider :other_fare_provider
          fare_zone :other_fare_zone
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation)
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:fare_zone) { context.fare_zone(:fare_zone) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:base_fare_zone_attrs) { { 'name' => 'test' } }
  let(:fare_zone_attrs) { base_fare_zone_attrs }

  before { @user.update(permissions: %w[fare_zones.create fare_zones.update fare_zones.destroy]) }

  describe 'GET #new' do
    let(:request) { get :new, params: base_params }

    before { request }

    it { is_expected.to render_template('fare_zones/new') }

    context 'when the params contain a fare provider' do
      let(:request) do
        get :new, params: base_params.merge({ 'fare_zone' => { 'fare_provider_id' => fare_provider.id.to_s } })
      end

      context 'of the current workbench' do
        let(:fare_provider) { context.fare_provider(:fare_provider) }
        it { is_expected.to render_template('fare_zones/new') }
      end

      context 'of another workbench' do
        let(:fare_provider) { context.fare_provider(:other_fare_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:request) { post :create, params: base_params.merge({ 'fare_zone' => fare_zone_attrs }) }

    it 'should create a new fare zone' do
      expect { request }.to change { workbench.fare_zones.count }.by 1
    end

    it 'assigns default fare provider' do
      request
      expect(workbench.fare_zones.last.fare_provider).to eq(workbench.default_fare_provider)
    end

    context 'with a fare provider' do
      let(:fare_zone_attrs) { base_fare_zone_attrs.merge({ 'fare_provider_id' => fare_provider.id.to_s }) }

      before { request }

      context 'of the current workbench' do
        let(:fare_provider) { context.fare_provider(:fare_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:fare_provider) { context.fare_provider(:other_fare_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'GET #edit' do
    let(:request) { get :edit, params: base_params.merge({ 'id' => fare_zone.id.to_s }) }

    before { request }

    it { is_expected.to render_template('fare_zones/edit') }

    context 'when the fare provider workbench is not the same as the current workbench' do
      let(:fare_zone) { context.fare_zone(:other_fare_zone) }
      it { expect(response).to have_http_status(:not_found) }
    end
  end

  describe 'PUT #update' do
    let(:request) do
      put :update, params: base_params.merge({ 'id' => fare_zone.id.to_s, 'fare_zone' => fare_zone_attrs })
    end

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { fare_zone.reload }.to change { fare_zone.name }.to('test') }

    context 'when the fare provider workbench is not the same as the current workbench' do
      let(:fare_zone) { context.fare_zone(:other_fare_zone) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the params contain a fare provider' do
      let(:fare_zone_attrs) { base_fare_zone_attrs.merge({ 'fare_provider_id' => fare_provider.id.to_s }) }

      context 'of the current workbench' do
        let(:fare_provider) { context.fare_provider(:fare_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:fare_provider) { context.fare_provider(:other_fare_provider) }
        it { is_expected.to render_template('fare_zones/edit') }
      end
    end
  end
end
