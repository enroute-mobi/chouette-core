# frozen_string_literal: true

RSpec.describe ShapesController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          shape_provider :shape_provider
          shape :shape
        end
        workbench(organisation: organisation) do
          shape_provider :other_shape_provider
          shape :other_shape # same shape referential as :shape
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation)
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:shape_referential) { workbench.shape_referential }
  let(:shape) { context.shape(:shape) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:base_shape_attrs) { { 'name' => 'test', 'geometry' => 'LINESTRING(48.8584 2.2945,48.859 2.295)' } }
  let(:shape_attrs) { base_shape_attrs }

  before { @user.update(permissions: %w[shapes.create shapes.update shapes.destroy]) }

  describe 'GET #index' do
    let(:context) do
      Chouette.create do
        workbench(:workbench, organisation: Organisation.find_by(code: 'first')) do
          shape :first
          shape :second
        end
      end
    end

    it 'should be successful' do
      get :index, params: base_params
      expect(response).to be_successful
      expect(assigns(:shapes)).to include(context.shape(:first))
      expect(assigns(:shapes)).to include(context.shape(:second))
    end

    context 'with filters' do
      let(:title_or_content_cont) { line_notices.first.title }
      let(:lines_id_eq) { line_notices.last.lines.first.id }

      it 'should filter on name or uuid' do
        get :index, params: base_params.merge({ 'q' => { 'name_or_uuid_cont' => context.shape(:first).name } })
        expect(response).to be_successful
        expect(assigns(:shapes)).to include(context.shape(:first))
        expect(assigns(:shapes)).to_not include(context.shape(:second))
      end
    end
  end

  describe 'GET show' do
    let(:context) do
      Chouette.create do
        workbench(:workbench, organisation: Organisation.find_by(code: 'first')) do
          shape :first
        end
      end
    end

    it 'should be successful' do
      get :show, params: base_params.merge({ 'id' => context.shape(:first).id.to_s })
      expect(response).to be_successful
    end
  end

  describe 'GET #edit' do
    let(:request) { get :edit, params: base_params.merge({ 'id' => shape.id.to_s }) }

    before { request }

    it { is_expected.to render_template('shapes/edit') }

    context 'when the shape referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the shape provider workbench is not the same as the current workbench' do
      let(:shape) { context.shape(:other_shape) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe 'PUT #update' do
    let(:request) { put :update, params: base_params.merge({ 'id' => shape.id.to_s, 'shape' => shape_attrs }) }

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { shape.reload }.to change { shape.name }.to('test') }

    context 'when the shape referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the shape provider workbench is not the same as the current workbench' do
      let(:shape) { context.shape(:other_shape) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when the params contain a shape provider' do
      let(:shape_attrs) { base_shape_attrs.merge({ 'shape_provider_id' => shape_provider.id.to_s }) }

      context 'of the current workbench' do
        let(:shape_provider) { context.shape_provider(:shape_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:shape_provider) { context.shape_provider(:other_shape_provider) }
        it { is_expected.to render_template('shapes/edit') }
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:context) do
      Chouette.create do
        workbench(:workbench, organisation: Organisation.find_by(code: 'first')) do
          shape :first
        end
      end
    end

    it 'should be successful' do
      context
      expect do
        delete :destroy, params: base_params.merge('id' => context.shape(:first).id.to_s)
      end.to change(Shape, :count).by(-1)
      expect(response).to redirect_to workbench_shape_referential_shapes_path(workbench)
    end
  end
end
