# frozen_string_literal: true

RSpec.describe EquipementsController, type: :controller do
  login_user

  let(:permissions) { %w[equipements.create equipements.update equipements.destroy] }

  let(:context) do
    organisation = self.organisation
    Chouette.create do
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          stop_area :stop_area
          shape_provider :shape_provider do
            equipement :equipement, stop_area: :stop_area
          end
        end
        workbench(organisation: organisation) do
          stop_area :other_stop_area
          shape_provider :other_shape_provider do
            equipement :other_equipement, stop_area: :other_stop_area # same shape referential as :equipement
          end
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation)
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:shape_referential) { workbench.shape_referential }
  let(:equipement) { context.equipement(:equipement) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:base_equipement_attrs) do
    { 'name' => 'test', 'stop_area_id' => context.stop_area(:stop_area).id.to_s }
  end
  let(:equipement_attrs) { base_equipement_attrs }

  describe 'GET #new' do
    let(:request) { get :new, params: base_params }

    before { request }

    it { is_expected.to render_template('equipements/new') }

    context 'when the params contain a shape provider' do
      let(:request) do
        get :new, params: base_params.merge({ 'equipement' => { 'shape_provider_id' => shape_provider.id.to_s } })
      end

      context 'of the current workbench' do
        let(:shape_provider) { context.shape_provider(:shape_provider) }
        it { is_expected.to render_template('equipements/new') }
      end

      context 'of another workbench' do
        let(:shape_provider) { context.shape_provider(:other_shape_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:request) { post :create, params: base_params.merge({ 'equipement' => equipement_attrs }) }

    it 'should create a new equipement' do
      expect { request }.to change { shape_referential.equipements.count }.by 1
    end

    it 'assigns default shape provider' do
      request
      expect(shape_referential.equipements.last.shape_provider).to eq(workbench.default_shape_provider)
    end

    context 'with a shape provider' do
      let(:equipement_attrs) { base_equipement_attrs.merge({ 'shape_provider_id' => shape_provider.id.to_s }) }

      before { request }

      context 'of the current workbench' do
        let(:shape_provider) { context.shape_provider(:shape_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:shape_provider) { context.shape_provider(:other_shape_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'GET #edit' do
    let(:request) { get :edit, params: base_params.merge({ 'id' => equipement.id.to_s }) }

    before { request }

    it { is_expected.to render_template('equipements/edit') }

    context 'when the shape referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the shape provider workbench is not the same as the current workbench' do
      let(:equipement) { context.equipement(:other_equipement) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe 'PUT #update' do
    let(:request) do
      put :update, params: base_params.merge({ 'id' => equipement.id.to_s, 'equipement' => equipement_attrs })
    end

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { equipement.reload }.to change { equipement.name }.to('test') }

    context 'when the shape referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the shape provider workbench is not the same as the current workbench' do
      let(:equipement) { context.equipement(:other_equipement) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when the params contain a shape provider' do
      let(:equipement_attrs) { base_equipement_attrs.merge({ 'shape_provider_id' => shape_provider.id.to_s }) }

      context 'of the current workbench' do
        let(:shape_provider) { context.shape_provider(:shape_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:shape_provider) { context.shape_provider(:other_shape_provider) }
        it { is_expected.to render_template('equipements/edit') }
      end
    end
  end
end
