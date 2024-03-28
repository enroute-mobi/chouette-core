# frozen_string_literal: true

RSpec.describe EntrancesController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          stop_area_provider :stop_area_provider
          stop_area :stop_area do
            entrance :entrance
          end
        end
        workbench(organisation: organisation) do
          stop_area_provider :other_stop_area_provider
          entrance :other_entrance # same stop area referential as :entrance
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation)
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:stop_area_referential) { workbench.stop_area_referential }
  let(:entrance) { context.entrance(:entrance) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:base_entrance_attrs) do
    { 'name' => 'test', 'stop_area_id' => context.stop_area(:stop_area).id.to_s }
  end
  let(:entrance_attrs) { base_entrance_attrs }

  before { @user.update(permissions: %w[entrances.create entrances.update entrances.destroy]) }

  describe 'GET #new' do
    let(:request) { get :new, params: base_params }

    before { request }

    it { is_expected.to render_template('entrances/new') }

    context 'when the params contain a stop area provider' do
      let(:request) do
        get :new, params: base_params.merge({ 'entrance' => { 'stop_area_provider_id' => stop_area_provider.id.to_s } })
      end

      context 'of the current workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:stop_area_provider) }
        it { is_expected.to render_template('entrances/new') }
      end

      context 'of another workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:other_stop_area_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:request) { post :create, params: base_params.merge({ 'entrance' => entrance_attrs }) }

    it 'should create a new entrance' do
      expect { request }.to change { stop_area_referential.entrances.count }.by 1
    end

    it 'assigns default stop area provider' do
      request
      expect(stop_area_referential.entrances.last.stop_area_provider).to eq(workbench.default_stop_area_provider)
    end

    context 'with a stop area provider' do
      let(:entrance_attrs) { base_entrance_attrs.merge({ 'stop_area_provider_id' => stop_area_provider.id.to_s }) }

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
    let(:request) { get :edit, params: base_params.merge({ 'id' => entrance.id.to_s }) }

    before { request }

    it { is_expected.to render_template('entrances/edit') }

    context 'when the stop area referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the stop area provider workbench is not the same as the current workbench' do
      let(:entrance) { context.entrance(:other_entrance) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe 'PUT #update' do
    let(:request) do
      put :update, params: base_params.merge({ 'id' => entrance.id.to_s, 'entrance' => entrance_attrs })
    end

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { entrance.reload }.to change { entrance.name }.to('test') }

    context 'when the stop area referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the stop area provider workbench is not the same as the current workbench' do
      let(:entrance) { context.entrance(:other_entrance) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when the params contain a entrance provider' do
      let(:entrance_attrs) { base_entrance_attrs.merge({ 'stop_area_provider_id' => stop_area_provider.id.to_s }) }

      context 'of the current workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:stop_area_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:other_stop_area_provider) }
        it { is_expected.to render_template('entrances/edit') }
      end
    end
  end
end
