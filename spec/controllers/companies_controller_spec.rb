# frozen_string_literal: true

RSpec.describe CompaniesController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          line_provider :line_provider
          company :company
        end
        workbench(organisation: organisation) do
          line_provider :other_line_provider
          company :other_company # same line referential as :company
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation)
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:line_referential) { workbench.line_referential }
  let(:company) { context.company(:company) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:base_company_attrs) { { 'name' => 'test' } }
  let(:company_attrs) { base_company_attrs }

  before { @user.update(permissions: %w[companies.create companies.update companies.destroy]) }

  describe 'GET #new' do
    let(:request) { get :new, params: base_params }

    before { request }

    it { is_expected.to render_template('companies/new') }

    context 'when the params contain a line provider' do
      let(:request) do
        get :new, params: base_params.merge({ 'company' => { 'line_provider_id' => line_provider.id.to_s } })
      end

      context 'of the current workbench' do
        let(:line_provider) { context.line_provider(:line_provider) }
        it { is_expected.to render_template('companies/new') }
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:request) { post :create, params: base_params.merge({ 'company' => company_attrs }) }

    it 'should create a new company' do
      expect { request }.to change { line_referential.companies.count }.by 1
    end

    it 'assigns default line provider' do
      request
      expect(line_referential.companies.last.line_provider).to eq(workbench.default_line_provider)
    end

    context 'with a line provider' do
      let(:company_attrs) { base_company_attrs.merge({ 'line_provider_id' => line_provider.id.to_s }) }

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
    let(:request) { get :edit, params: base_params.merge({ 'id' => company.id.to_s }) }

    before { request }

    it { is_expected.to render_template('companies/edit') }

    context 'when the line referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the line provider workbench is not the same as the current workbench' do
      let(:company) { context.company(:other_company) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe 'PUT #update' do
    let(:request) { put :update, params: base_params.merge({ 'id' => company.id.to_s, 'company' => company_attrs }) }

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { company.reload }.to change { company.name }.to('test') }

    context 'when the line referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the line provider workbench is not the same as the current workbench' do
      let(:company) { context.company(:other_company) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when the params contain a line provider' do
      let(:company_attrs) { base_company_attrs.merge({ 'line_provider_id' => line_provider.id.to_s }) }

      context 'of the current workbench' do
        let(:line_provider) { context.line_provider(:line_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        it { is_expected.to render_template('companies/edit') }
      end
    end
  end
end
