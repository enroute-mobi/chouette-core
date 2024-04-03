# frozen_string_literal: true

RSpec.describe StopAreasController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          stop_area_provider :stop_area_provider
          stop_area :stop_area
        end
        workbench(organisation: organisation) do
          stop_area_provider :other_stop_area_provider
          stop_area :other_stop_area # same stop area referential as :stop_area
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation)
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:stop_area_referential) { workbench.stop_area_referential }
  let(:stop_area) { context.stop_area(:stop_area) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:base_stop_area_attrs) { { 'name' => 'test' } }
  let(:stop_area_attrs) { base_stop_area_attrs }

  before { @user.update(permissions: %w[stop_areas.create stop_areas.update stop_areas.destroy]) }

  describe 'GET #index' do
    subject(:request) { get :index, params: base_params }

    it 'calls set_current_workgroup' do
      expect(controller).to receive(:set_current_workgroup)
      subject
    end
  end

  describe 'GET #new' do
    let(:request) { get :new, params: base_params }

    before { request }

    it { is_expected.to render_template('stop_areas/new') }

    context 'when the params contain a stop area provider' do
      let(:request) do
        get :new, params: base_params.merge(
          { 'stop_area' => { 'stop_area_provider_id' => stop_area_provider.id.to_s } }
        )
      end

      context 'of the current workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:stop_area_provider) }
        it { is_expected.to render_template('stop_areas/new') }
      end

      context 'of another workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:other_stop_area_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:request) { post :create, params: base_params.merge({ 'stop_area' => stop_area_attrs }) }

    it 'should create a new stop area' do
      expect { request }.to change { stop_area_referential.stop_areas.count }.by 1
    end

    it 'assigns default stop area provider' do
      request
      expect(stop_area_referential.stop_areas.last.stop_area_provider).to eq(workbench.default_stop_area_provider)
    end

    context 'with a stop area provider' do
      let(:stop_area_attrs) { base_stop_area_attrs.merge({ 'stop_area_provider_id' => stop_area_provider.id.to_s }) }

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
    let(:request) { get :edit, params: base_params.merge({ 'id' => stop_area.id.to_s }) }

    before { request }

    it { is_expected.to render_template('stop_areas/edit') }

    context 'when the stop area referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the stop area provider workbench is not the same as the current workbench' do
      let(:stop_area) { context.stop_area(:other_stop_area) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe 'PUT #update' do
    let(:request) do
      put :update, params: base_params.merge({ 'id' => stop_area.id.to_s, 'stop_area' => stop_area_attrs })
    end

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { stop_area.reload }.to change { stop_area.name }.to('test') }

    context 'when the stop area referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the stop area provider workbench is not the same as the current workbench' do
      let(:stop_area) { context.stop_area(:other_stop_area) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when the params contain a stop_area provider' do
      let(:stop_area_attrs) { base_stop_area_attrs.merge({ 'stop_area_provider_id' => stop_area_provider.id.to_s }) }

      context 'of the current workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:stop_area_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:other_stop_area_provider) }
        it { is_expected.to render_template('stop_areas/edit') }
      end
    end
  end
end
