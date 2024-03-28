# frozen_string_literal: true

RSpec.describe LinesController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          line_provider :line_provider
          line :line
        end
        workbench(organisation: organisation) do
          line_provider :other_line_provider
          line :other_line # same line referential as :line
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation)
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:line_referential) { workbench.line_referential }
  let(:line) { context.line(:line) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:base_line_attrs) { { 'name' => 'test', 'transport_mode' => 'bus', 'transport_submode' => 'undefined' } }
  let(:line_attrs) { base_line_attrs }

  before { @user.update(permissions: %w[lines.create lines.update lines.destroy]) }

  describe 'GET #new' do
    let(:request) { get :new, params: base_params }

    before { request }

    it { is_expected.to render_template('lines/new') }

    context 'when the params contain a line provider' do
      let(:request) do
        get :new, params: base_params.merge({ 'line' => { 'line_provider_id' => line_provider.id.to_s } })
      end

      context 'of the current workbench' do
        let(:line_provider) { context.line_provider(:line_provider) }
        it { is_expected.to render_template('lines/new') }
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:request) { post :create, params: base_params.merge({ 'line' => line_attrs }) }

    it 'should create a new line' do
      expect { request }.to change { line_referential.lines.count }.by 1
    end

    it 'assigns default line provider' do
      request
      expect(line_referential.lines.last.line_provider).to eq(workbench.default_line_provider)
    end

    context 'with an empty value in secondary_company_ids' do
      let(:line_attrs) { base_line_attrs.merge({ 'secondary_company_ids' => '' }) }

      it 'should cleanup secondary_company_ids' do
        expect { request }.to change { line_referential.lines.count }.by 1
        expect(line_referential.lines.last.secondary_company_ids).to eq []
      end
    end

    context 'with a line provider' do
      let(:line_attrs) { base_line_attrs.merge({ 'line_provider_id' => line_provider.id.to_s }) }

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
    let(:request) { get :edit, params: base_params.merge({ 'id' => line.id.to_s }) }

    before { request }

    it { is_expected.to render_template('lines/edit') }

    context 'when the line referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the line provider workbench is not the same as the current workbench' do
      let(:line) { context.line(:other_line) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe 'PUT #update' do
    let(:request) { put :update, params: base_params.merge({ 'id' => line.id.to_s, 'line' => line_attrs }) }

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { line.reload }.to change { line.name }.to('test') }

    context 'when the line referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the line provider workbench is not the same as the current workbench' do
      let(:line) { context.line(:other_line) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when the params contain a line provider' do
      let(:line_attrs) { base_line_attrs.merge({ 'line_provider_id' => line_provider.id.to_s }) }

      context 'of the current workbench' do
        let(:line_provider) { context.line_provider(:line_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        it { is_expected.to render_template('lines/edit') }
      end
    end
  end
end
