# frozen_string_literal: true

RSpec.describe ConnectionLinksController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          stop_area_provider :stop_area_provider
          stop_area :departure
          stop_area :arrival
          connection_link :connection_link, departure: :departure, arrival: :arrival
        end
        workbench(organisation: organisation) do
          stop_area_provider :other_stop_area_provider
          # same stop area referential as :connection_link
          connection_link :other_connection_link, departure: :departure, arrival: :arrival
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation)
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:stop_area_referential) { workbench.stop_area_referential }
  let(:connection_link) { context.connection_link(:connection_link) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:base_connection_link_attrs) do
    {
      'name' => 'test',
      'departure_id' => context.stop_area(:departure).id.to_s,
      'arrival_id' => context.stop_area(:arrival).id.to_s,
      'default_duration_in_min' => '0'
    }
  end
  let(:connection_link_attrs) { base_connection_link_attrs }

  before { @user.update(permissions: %w[connection_links.create connection_links.update connection_links.destroy]) }

  describe 'GET #new' do
    let(:request) { get :new, params: base_params }

    before { request }

    it { is_expected.to render_template('connection_links/new') }

    context 'when the params contain a stop area provider' do
      let(:request) do
        get :new, params: base_params.merge(
          { 'connection_link' => { 'stop_area_provider_id' => stop_area_provider.id.to_s } }
        )
      end

      context 'of the current workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:stop_area_provider) }
        it { is_expected.to render_template('connection_links/new') }
      end

      context 'of another workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:other_stop_area_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:request) { post :create, params: base_params.merge({ 'connection_link' => connection_link_attrs }) }

    it 'should create a new connection link' do
      expect { request }.to change { stop_area_referential.connection_links.count }.by 1
    end

    it 'assigns default stop area provider' do
      request
      expect(stop_area_referential.connection_links.last.stop_area_provider).to eq(workbench.default_stop_area_provider)
    end

    context 'with a stop area provider' do
      let(:connection_link_attrs) do
        base_connection_link_attrs.merge({ 'stop_area_provider_id' => stop_area_provider.id.to_s })
      end

      before { request }

      context 'of the current workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:stop_area_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:other_stop_area_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'GET #edit' do
    let(:request) { get :edit, params: base_params.merge({ 'id' => connection_link.id.to_s }) }

    before { request }

    it { is_expected.to render_template('connection_links/edit') }

    context 'when the stop area referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the stop area provider workbench is not the same as the current workbench' do
      let(:connection_link) { context.connection_link(:other_connection_link) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe 'PUT #update' do
    let(:request) do
      put :update, params: base_params.merge(
        { 'id' => connection_link.id.to_s, 'connection_link' => connection_link_attrs }
      )
    end

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { connection_link.reload }.to change { connection_link.name }.to('test') }

    context 'when the stop area referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the stop area provider workbench is not the same as the current workbench' do
      let(:connection_link) { context.connection_link(:other_connection_link) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when the params contain a entrance provider' do
      let(:connection_link_attrs) do
        base_connection_link_attrs.merge({ 'stop_area_provider_id' => stop_area_provider.id.to_s })
      end

      context 'of the current workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:stop_area_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:other_stop_area_provider) }
        it { is_expected.to render_template('connection_links/edit') }
      end
    end
  end
end
