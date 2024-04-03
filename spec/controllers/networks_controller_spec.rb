# frozen_string_literal: true

RSpec.describe NetworksController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          line_provider :line_provider
          network :network
        end
        workbench(organisation: organisation) do
          line_provider :other_line_provider
          network :other_network # same line referential as :network
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation)
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:line_referential) { workbench.line_referential }
  let(:network) { context.network(:network) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:base_network_attrs) { { 'name' => 'test' } }
  let(:network_attrs) { base_network_attrs }

  before { @user.update(permissions: %w[networks.create networks.update networks.destroy]) }

  describe 'GET #new' do
    let(:request) { get :new, params: base_params }

    before { request }

    it { is_expected.to render_template('networks/new') }

    context 'when the params contain a line provider' do
      let(:request) do
        get :new, params: base_params.merge({ 'network' => { 'line_provider_id' => line_provider.id.to_s } })
      end

      context 'of the current workbench' do
        let(:line_provider) { context.line_provider(:line_provider) }
        it { is_expected.to render_template('networks/new') }
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:request) { post :create, params: base_params.merge({ 'network' => network_attrs }) }

    it 'should create a new network' do
      expect { request }.to change { line_referential.networks.count }.by 1
    end

    it 'assigns default line provider' do
      request
      expect(line_referential.networks.last.line_provider).to eq(workbench.default_line_provider)
    end

    context 'with a line provider' do
      let(:network_attrs) { base_network_attrs.merge({ 'line_provider_id' => line_provider.id.to_s }) }

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
    let(:request) { get :edit, params: base_params.merge({ 'id' => network.id.to_s }) }

    before { request }

    it { is_expected.to render_template('networks/edit') }

    context 'when the line referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the line provider workbench is not the same as the current workbench' do
      let(:network) { context.network(:other_network) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe 'PUT #update' do
    let(:request) { put :update, params: base_params.merge({ 'id' => network.id.to_s, 'network' => network_attrs }) }

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { network.reload }.to change { network.name }.to('test') }

    context 'when the line referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the line provider workbench is not the same as the current workbench' do
      let(:network) { context.network(:other_network) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when the params contain a line provider' do
      let(:network_attrs) { base_network_attrs.merge({ 'line_provider_id' => line_provider.id.to_s }) }

      context 'of the current workbench' do
        let(:line_provider) { context.line_provider(:line_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        it { is_expected.to render_template('networks/edit') }
      end
    end
  end
end
