# frozen_string_literal: true

RSpec.describe PointOfInterestCategoriesController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          shape_provider :shape_provider
          point_of_interest_category :point_of_interest_category
        end
        workbench(organisation: organisation) do
          shape_provider :other_shape_provider
          # same shape referential as :point_of_interest_category
          point_of_interest_category :other_point_of_interest_category
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation)
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:shape_referential) { workbench.shape_referential }
  let(:point_of_interest_category) { context.point_of_interest_category(:point_of_interest_category) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:base_point_of_interest_category_attrs) { { 'name' => 'test' } }
  let(:point_of_interest_category_attrs) { base_point_of_interest_category_attrs }

  before do
    @user.update(
      permissions: %w[
        point_of_interest_categories.create
        point_of_interest_categories.update
        point_of_interest_categories.destroy
      ]
    )
  end

  describe 'GET #new' do
    let(:request) { get :new, params: base_params }

    before { request }

    it { is_expected.to render_template('point_of_interest_categories/new') }

    context 'when the params contain a shape provider' do
      let(:request) do
        get :new, params: base_params.merge(
          { 'point_of_interest_category' => { 'shape_provider_id' => shape_provider.id.to_s } }
        )
      end

      context 'of the current workbench' do
        let(:shape_provider) { context.shape_provider(:shape_provider) }
        it { is_expected.to render_template('point_of_interest_categories/new') }
      end

      context 'of another workbench' do
        let(:shape_provider) { context.shape_provider(:other_shape_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:request) do
      post :create, params: base_params.merge({ 'point_of_interest_category' => point_of_interest_category_attrs })
    end

    it 'should create a new point of interest category' do
      expect { request }.to change { shape_referential.point_of_interest_categories.count }.by 1
    end

    it 'assigns default shape provider' do
      request
      expect(shape_referential.point_of_interest_categories.last.shape_provider).to eq(workbench.default_shape_provider)
    end

    context 'with a shape provider' do
      let(:point_of_interest_category_attrs) do
        base_point_of_interest_category_attrs.merge({ 'shape_provider_id' => shape_provider.id.to_s })
      end

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
    let(:request) { get :edit, params: base_params.merge({ 'id' => point_of_interest_category.id.to_s }) }

    before { request }

    it { is_expected.to render_template('point_of_interest_categories/edit') }

    context 'when the shape referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the shape provider workbench is not the same as the current workbench' do
      let(:point_of_interest_category) { context.point_of_interest_category(:other_point_of_interest_category) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe 'PUT #update' do
    let(:request) do
      put :update, params: base_params.merge(
        { 'id' => point_of_interest_category.id.to_s, 'point_of_interest_category' => point_of_interest_category_attrs }
      )
    end

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { point_of_interest_category.reload }.to change { point_of_interest_category.name }.to('test') }

    context 'when the shape referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the shape provider workbench is not the same as the current workbench' do
      let(:point_of_interest_category) { context.point_of_interest_category(:other_point_of_interest_category) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when the params contain a shape provider' do
      let(:point_of_interest_category_attrs) do
        base_point_of_interest_category_attrs.merge({ 'shape_provider_id' => shape_provider.id.to_s })
      end

      context 'of the current workbench' do
        let(:shape_provider) { context.shape_provider(:shape_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:shape_provider) { context.shape_provider(:other_shape_provider) }
        it { is_expected.to render_template('point_of_interest_categories/edit') }
      end
    end
  end
end
