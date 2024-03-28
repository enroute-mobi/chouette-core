# frozen_string_literal: true

RSpec.describe DocumentsController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(owner: organisation) do
        document_type :document_type
        workbench(:workbench, organisation: organisation) do
          document_provider :document_provider
          document :document, document_type: :document_type
        end
        workbench(organisation: organisation) do
          document_provider :other_document_provider
          document :other_document, document_type: :document_type
        end
      end
      workgroup do
        document_type :other_document_type
        workbench(:other_workbench, organisation: organisation)
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:document) { context.document(:document) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:document_type) { context.document_type(:document_type) }
  let(:file) { fixture_file_upload('sample_pdf.pdf') }
  let(:base_document_attrs) do
    {
      'name' => 'test',
      'document_type_id' => document_type.id.to_s,
      'file' => file,
      'file_cache' => '',
      'validity_period' => (Time.zone.today...Time.zone.today + 1.day).to_s
    }
  end
  let(:document_attrs) { base_document_attrs }

  before { @user.update(permissions: %w[documents.create documents.update documents.destroy]) }

  describe 'GET #new' do
    let(:request) { get :new, params: base_params }

    before { request }

    it { is_expected.to render_template('documents/new') }

    context 'when the params contain a document provider' do
      let(:request) do
        get :new, params: base_params.merge({ 'document' => { 'document_provider_id' => document_provider.id.to_s } })
      end

      context 'of the current workbench' do
        let(:document_provider) { context.document_provider(:document_provider) }
        it { is_expected.to render_template('documents/new') }
      end

      context 'of another workbench' do
        let(:document_provider) { context.document_provider(:other_document_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:request) { post :create, params: base_params.merge({ 'document' => document_attrs }) }

    it 'should create a new document' do
      expect { request }.to change { workbench.documents.count }.by 1
    end

    it 'assigns default document provider' do
      request
      expect(workbench.documents.last.document_provider).to eq(workbench.default_document_provider)
    end

    context 'with a document provider' do
      let(:document_attrs) { base_document_attrs.merge({ 'document_provider_id' => document_provider.id.to_s }) }

      before { request }

      context 'of the current workbench' do
        let(:document_provider) { context.document_provider(:document_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:document_provider) { context.document_provider(:other_document_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end

    context 'with a document type of another workgroup' do
      let(:document_type) { context.document_type(:other_document_type) }
      before { request }
      it { is_expected.to render_template('documents/new') }
    end
  end

  describe 'GET #edit' do
    let(:request) { get :edit, params: base_params.merge({ 'id' => document.id.to_s }) }

    before { request }

    it { is_expected.to render_template('documents/edit') }

    context 'when the document provider workbench is not the same as the current workbench' do
      let(:document) { context.document(:other_document) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe 'PUT #update' do
    let(:request) { put :update, params: base_params.merge({ 'id' => document.id.to_s, 'document' => document_attrs }) }

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { document.reload }.to change { document.name }.to('test') }

    context 'when the document provider workbench is not the same as the current workbench' do
      let(:document) { context.document(:other_document) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when the params contain a document provider' do
      let(:document_attrs) { base_document_attrs.merge({ 'document_provider_id' => document_provider.id.to_s }) }

      context 'of the current workbench' do
        let(:document_provider) { context.document_provider(:document_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:document_provider) { context.document_provider(:other_document_provider) }
        it { is_expected.to render_template('documents/edit') }
      end
    end

    context 'with a document type of another workgroup' do
      let(:document_type) { context.document_type(:other_document_type) }
      it { is_expected.to render_template('documents/edit') }
    end
  end
end
