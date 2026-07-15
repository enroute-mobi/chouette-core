# frozen_string_literal: true

RSpec.describe EquipmentsController, type: :controller do
  login_user

  let(:permissions) { %w[equipments.create equipments.update equipments.destroy] }

  let(:context) do
    organisation = self.organisation
    Chouette.create do
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          stop_area_provider :stop_area_provider
          stop_area :stop_area do
            equipment :equipment
          end
        end
        workbench(organisation: organisation) do
          stop_area_provider :other_stop_area_provider
          stop_area do
            equipment :other_equipment # same stop area referential as :equipment
          end
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation)
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:stop_area_referential) { workbench.stop_area_referential }
  let(:equipment) { context.equipment(:equipment) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:base_equipment_attrs) do
    { 'name' => 'test', 'stop_area_id' => context.stop_area(:stop_area).id.to_s }
  end
  let(:equipment_attrs) { base_equipment_attrs }

  describe 'GET #new' do
    let(:request) { get :new, params: base_params }

    before { request }

    it { is_expected.to render_template('equipments/new') }

    context 'when the params contain a stop area provider' do
      let(:request) do
        get :new,
            params: base_params.merge({ 'equipment' => { 'stop_area_provider_id' => stop_area_provider.id.to_s } })
      end

      context 'of the current workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:stop_area_provider) }
        it { is_expected.to render_template('equipments/new') }
      end

      context 'of another workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:other_stop_area_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:request) { post :create, params: base_params.merge({ 'equipment' => equipment_attrs }) }

    it 'should create a new equipment' do
      expect { request }.to change { stop_area_referential.equipments.count }.by 1
    end

    it 'assigns default stop area provider' do
      request
      expect(stop_area_referential.equipments.last.stop_area_provider).to eq(workbench.default_stop_area_provider)
    end

    context 'with a stop area provider' do
      let(:equipment_attrs) { base_equipment_attrs.merge({ 'stop_area_provider_id' => stop_area_provider.id.to_s }) }

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
    let(:request) { get :edit, params: base_params.merge({ 'id' => equipment.id.to_s }) }

    before { request }

    it { is_expected.to render_template('equipments/edit') }

    context 'when the stop area referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the stop area provider workbench is not the same as the current workbench' do
      let(:equipment) { context.equipment(:other_equipment) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe 'PUT #update' do
    let(:request) do
      put :update, params: base_params.merge({ 'id' => equipment.id.to_s, 'equipment' => equipment_attrs })
    end

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { equipment.reload }.to change { equipment.name }.to('test') }

    context 'when the stop area referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the stop area provider workbench is not the same as the current workbench' do
      let(:equipment) { context.equipment(:other_equipment) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when the params contain a stop area provider' do
      let(:equipment_attrs) { base_equipment_attrs.merge({ 'stop_area_provider_id' => stop_area_provider.id.to_s }) }

      context 'of the current workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:stop_area_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:other_stop_area_provider) }
        it { is_expected.to render_template('equipments/edit') }
      end
    end
  end
end
