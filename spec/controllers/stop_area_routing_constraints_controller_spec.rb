# frozen_string_literal: true

RSpec.describe StopAreaRoutingConstraintsController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          stop_area :stop_area1
          stop_area :stop_area2
          stop_area_provider :stop_area_provider
          stop_area_routing_constraint :stop_area_routing_constraint, from: :stop_area1, to: :stop_area2
        end
        workbench(organisation: organisation) do
          stop_area_provider :other_stop_area_provider
          # same stop area referential as :stop_area_routing_constraint
          stop_area_routing_constraint :other_stop_area_routing_constraint, from: :stop_area1, to: :stop_area2
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation)
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:stop_area_referential) { workbench.stop_area_referential }
  let(:stop_area_routing_constraint) { context.stop_area_routing_constraint(:stop_area_routing_constraint) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:base_stop_area_routing_constraint_attrs) do
    {
      'from_id' => context.stop_area(:stop_area1).id.to_s,
      'to_id' => context.stop_area(:stop_area2).id.to_s,
      'both_way' => '1'
    }
  end
  let(:stop_area_routing_constraint_attrs) { base_stop_area_routing_constraint_attrs }

  before do
    @user.organisation.update(
      features: %i[
        stop_area_routing_constraints
      ]
    )
    @user.update(
      permissions: %w[
        stop_area_routing_constraints.create
        stop_area_routing_constraints.update
        stop_area_routing_constraints.destroy
      ]
    )
  end

  describe 'GET #new' do
    let(:request) { get :new, params: base_params }

    before { request }

    it { is_expected.to render_template('stop_area_routing_constraints/new') }

    context 'when the params contain a stop area provider' do
      let(:request) do
        get :new, params: base_params.merge(
          { 'stop_area_routing_constraint' => { 'stop_area_provider_id' => stop_area_provider.id.to_s } }
        )
      end

      context 'of the current workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:stop_area_provider) }
        it { is_expected.to render_template('stop_area_routing_constraints/new') }
      end

      context 'of another workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:other_stop_area_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:request) do
      post :create, params: base_params.merge({ 'stop_area_routing_constraint' => stop_area_routing_constraint_attrs })
    end

    it 'should create a new stop area routing constraint' do
      expect { request }.to change { stop_area_referential.stop_area_routing_constraints.count }.by 1
    end

    it 'assigns default stop area provider' do
      request
      expect(
        stop_area_referential.stop_area_routing_constraints.last.stop_area_provider
      ).to eq(workbench.default_stop_area_provider)
    end

    context 'with a stop area provider' do
      let(:stop_area_routing_constraint_attrs) do
        base_stop_area_routing_constraint_attrs.merge({ 'stop_area_provider_id' => stop_area_provider.id.to_s })
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
    let(:request) { get :edit, params: base_params.merge({ 'id' => stop_area_routing_constraint.id.to_s }) }

    before { request }

    it { is_expected.to render_template('stop_area_routing_constraints/edit') }

    context 'when the stop area referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the stop area provider workbench is not the same as the current workbench' do
      let(:stop_area_routing_constraint) { context.stop_area_routing_constraint(:other_stop_area_routing_constraint) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe 'PUT #update' do
    let(:request) do
      put :update, params: base_params.merge(
        {
          'id' => stop_area_routing_constraint.id.to_s,
          'stop_area_routing_constraint' => stop_area_routing_constraint_attrs
        }
      )
    end

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { stop_area_routing_constraint.reload }.to change { stop_area_routing_constraint.both_way }.to(true) }

    context 'when the stop area referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the stop area provider workbench is not the same as the current workbench' do
      let(:stop_area_routing_constraint) { context.stop_area_routing_constraint(:other_stop_area_routing_constraint) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when the params contain a stop area provider' do
      let(:stop_area_routing_constraint_attrs) do
        base_stop_area_routing_constraint_attrs.merge({ 'stop_area_provider_id' => stop_area_provider.id.to_s })
      end

      context 'of the current workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:stop_area_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:stop_area_provider) { context.stop_area_provider(:other_stop_area_provider) }
        it { is_expected.to render_template('stop_area_routing_constraints/edit') }
      end
    end
  end
end
