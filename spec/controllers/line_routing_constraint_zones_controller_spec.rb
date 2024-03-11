# frozen_string_literal: true

RSpec.describe LineRoutingConstraintZonesController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          stop_area :stop_area1
          stop_area :stop_area2
          line_provider :line_provider
          line :line
          line_routing_constraint_zone :line_routing_constraint_zone,
                                       lines: %i[line],
                                       stop_areas: %i[stop_area1 stop_area2]
        end
        workbench(organisation: organisation) do
          line_provider :other_line_provider
          # same line referential as :line_routing_constraint_zone
          line_routing_constraint_zone :other_line_routing_constraint_zone,
                                       lines: %i[line],
                                       stop_areas: %i[stop_area1 stop_area2]
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation)
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:line_referential) { workbench.line_referential }
  let(:line_routing_constraint_zone) { context.line_routing_constraint_zone(:line_routing_constraint_zone) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:base_line_routing_constraint_zone_attrs) do
    {
      'name' => 'test',
      'lines' => [context.line(:line).id.to_s],
      'stop_areas' => [context.stop_area(:stop_area1).id.to_s, context.stop_area(:stop_area2).id.to_s]
    }
  end
  let(:line_routing_constraint_zone_attrs) { base_line_routing_constraint_zone_attrs }

  before do
    @user.update(
      permissions: %w[
        line_routing_constraint_zones.create
        line_routing_constraint_zones.update
        line_routing_constraint_zones.destroy
      ]
    )
  end

  describe 'GET #new' do
    let(:request) { get :new, params: base_params }

    before { request }

    it { is_expected.to render_template('line_routing_constraint_zones/new') }

    context 'when the params contain a line provider' do
      let(:request) do
        get :new, params: base_params.merge(
          { 'line_routing_constraint_zone' => { 'line_provider_id' => line_provider.id.to_s } }
        )
      end

      context 'of the current workbench' do
        let(:line_provider) { context.line_provider(:line_provider) }
        it { is_expected.to render_template('line_routing_constraint_zones/new') }
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:request) do
      post :create, params: base_params.merge({ 'line_routing_constraint_zone' => line_routing_constraint_zone_attrs })
    end

    it 'should create a new line routing constraint zone' do
      expect { request }.to change { line_referential.line_routing_constraint_zones.count }.by 1
    end

    it 'assigns default line provider' do
      request
      expect(line_referential.line_routing_constraint_zones.last.line_provider).to eq(workbench.default_line_provider)
    end

    context 'with a line provider' do
      let(:line_routing_constraint_zone_attrs) do
        base_line_routing_constraint_zone_attrs.merge({ 'line_provider_id' => line_provider.id.to_s })
      end

      before { request }

      context 'of the current workbench' do
        let(:line_provider) { context.line_provider(:line_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'GET #edit' do
    let(:request) { get :edit, params: base_params.merge({ 'id' => line_routing_constraint_zone.id.to_s }) }

    before { request }

    it { is_expected.to render_template('line_routing_constraint_zones/edit') }

    context 'when the line referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the line provider workbench is not the same as the current workbench' do
      let(:line_routing_constraint_zone) { context.line_routing_constraint_zone(:other_line_routing_constraint_zone) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe 'PUT #update' do
    let(:request) do
      put :update, params: base_params.merge(
        {
          'id' => line_routing_constraint_zone.id.to_s,
          'line_routing_constraint_zone' => line_routing_constraint_zone_attrs
        }
      )
    end

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { line_routing_constraint_zone.reload }.to change { line_routing_constraint_zone.name }.to('test') }

    context 'when the line referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the line provider workbench is not the same as the current workbench' do
      let(:line_routing_constraint_zone) { context.line_routing_constraint_zone(:other_line_routing_constraint_zone) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when the params contain a line provider' do
      let(:line_routing_constraint_zone_attrs) do
        base_line_routing_constraint_zone_attrs.merge({ 'line_provider_id' => line_provider.id.to_s })
      end

      context 'of the current workbench' do
        let(:line_provider) { context.line_provider(:line_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        it { is_expected.to render_template('line_routing_constraint_zones/edit') }
      end
    end
  end
end
