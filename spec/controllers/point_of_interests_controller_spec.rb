# frozen_string_literal: true

RSpec.describe PointOfInterestsController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          shape_provider :shape_provider
          point_of_interest_category :point_of_interest_category
          point_of_interest :point_of_interest
        end
        workbench(organisation: organisation) do
          shape_provider :other_shape_provider
          point_of_interest_category :other_workbench_point_of_interest_category
          point_of_interest :other_point_of_interest # same shape referential as :point_of_interest
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation) do
          point_of_interest_category :other_workgroup_point_of_interest_category
        end
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:shape_referential) { workbench.shape_referential }
  let(:point_of_interest) { context.point_of_interest(:point_of_interest) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:point_of_interest_category) { context.point_of_interest_category(:point_of_interest_category) }
  let(:base_point_of_interest_attrs) do
    { 'name' => 'test', 'point_of_interest_category_id' => point_of_interest_category.id.to_s }
  end
  let(:point_of_interest_attrs) { base_point_of_interest_attrs }

  before do
    @user.update(permissions: %w[point_of_interests.create point_of_interests.update point_of_interests.destroy])
  end

  describe 'GET #new' do
    let(:request) { get :new, params: base_params }

    before { request }

    it { is_expected.to render_template('point_of_interests/new') }

    context 'when the params contain a shape provider' do
      let(:request) do
        get :new, params: base_params.merge(
          { 'point_of_interest' => { 'shape_provider_id' => shape_provider.id.to_s } }
        )
      end

      context 'of the current workbench' do
        let(:shape_provider) { context.shape_provider(:shape_provider) }
        it { is_expected.to render_template('point_of_interests/new') }
      end

      context 'of another workbench' do
        let(:shape_provider) { context.shape_provider(:other_shape_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:request) { post :create, params: base_params.merge({ 'point_of_interest' => point_of_interest_attrs }) }

    it 'should create a new point of interest' do
      expect { request }.to change { shape_referential.point_of_interests.count }.by 1
    end

    it 'assigns default shape provider' do
      request
      expect(shape_referential.point_of_interests.last.shape_provider).to eq(workbench.default_shape_provider)
    end

    context 'with a shape provider' do
      let(:point_of_interest_attrs) do
        base_point_of_interest_attrs.merge({ 'shape_provider_id' => shape_provider.id.to_s })
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

    context 'with a point of interest category' do
      context 'of another workbench but of the same referential' do
        let(:point_of_interest_category) do
          context.point_of_interest_category(:other_workbench_point_of_interest_category)
        end

        before { request }

        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workgroup' do
        let(:point_of_interest_category) do
          context.point_of_interest_category(:other_workgroup_point_of_interest_category)
        end

        before { request }

        it { is_expected.to render_template('point_of_interests/new') }
      end
    end
  end

  describe 'GET #edit' do
    let(:request) { get :edit, params: base_params.merge({ 'id' => point_of_interest.id.to_s }) }

    before { request }

    it { is_expected.to render_template('point_of_interests/edit') }

    context 'when the shape referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    xcontext 'when the shape provider workbench is not the same as the current workbench' do
      let(:point_of_interest) { context.point_of_interest(:other_point_of_interest) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe 'PUT #update' do
    let(:request) do
      put :update, params: base_params.merge(
        { 'id' => point_of_interest.id.to_s, 'point_of_interest' => point_of_interest_attrs }
      )
    end

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { point_of_interest.reload }.to change { point_of_interest.name }.to('test') }

    context 'when the shape referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    xcontext 'when the shape provider workbench is not the same as the current workbench' do
      let(:point_of_interest) { context.point_of_interest(:other_point_of_interest) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when the params contain a shape provider' do
      let(:point_of_interest_attrs) do
        base_point_of_interest_attrs.merge({ 'shape_provider_id' => shape_provider.id.to_s })
      end

      context 'of the current workbench' do
        let(:shape_provider) { context.shape_provider(:shape_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:shape_provider) { context.shape_provider(:other_shape_provider) }
        it { is_expected.to render_template('point_of_interests/edit') }
      end
    end

    context 'with a point of interest category' do
      context 'of another workbench but of the same referential' do
        let(:point_of_interest_category) do
          context.point_of_interest_category(:other_workbench_point_of_interest_category)
        end

        before { request }

        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workgroup' do
        let(:point_of_interest_category) do
          context.point_of_interest_category(:other_workgroup_point_of_interest_category)
        end

        before { request }

        it { is_expected.to render_template('point_of_interests/edit') }
      end
    end
  end
end
