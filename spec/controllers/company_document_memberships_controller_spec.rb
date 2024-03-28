# frozen_string_literal: true

RSpec.describe CompanyDocumentMembershipsController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      workgroup do
        document_type :document_type

        workbench organisation: Organisation.find_by(code: 'first') do
          document_provider :document_provider

          company :c1, name: 'Company one', short_name: 'c1'
          company :other_company

          document :document, document_type: :document_type, document_provider: :document_provider
          document :unassociated_document, document_type: :document_type, document_provider: :document_provider
        end
      end
    end
  end

  let(:workbench) { context.workbench }
  let(:company) { context.company(:c1) }
  let(:redirect_path) { workbench_line_referential_company_document_memberships_path(workbench, company) }

  let(:document) { context.document(:document) }
  let(:unassociated_document) { context.document(:unassociated_document) }

  let(:company_policy_update) { true }
  let(:company_policy) { double(update: company_policy_update) }
  let(:document_membership_policy) { double }

  describe 'GET #index' do
    before do
      company.documents << document
      unassociated_document
    end

    context 'when user cannot update companies' do
      before { expect(controller).to receive(:parent_policy).and_return(double(update?: false)) }

      it 'does not return unassociated documents' do
        get :index, params: { workbench_id: workbench.id, company_id: company.id }
        expect(assigns(:document_memberships).map(&:document)).to eq([document])
        expect(assigns(:unassociated_documents).map(&:document)).to eq([])
      end
    end

    context 'when user can update companies' do
      before { expect(controller).to receive(:parent_policy).and_return(double(update?: true)) }

      it 'returns unassociated documents' do
        get :index, params: { workbench_id: workbench.id, company_id: company.id }
        expect(assigns(:document_memberships).map(&:document)).to eq([document])
        expect(assigns(:unassociated_documents).map(&:document)).to eq([unassociated_document])
      end
    end
  end

  describe 'POST #create' do
    before do
      allow(Policy::Authorizer::Controller).to receive(:default_class).and_return(Policy::Authorizer::PermitAll)
    end

    it 'associates document' do
      post :create, params: { workbench_id: workbench.id, company_id: company.id, document_id: document.id }
      expect(company.reload.documents).to eq([document])
      expect(flash[:success]).to be_present
      expect(response).to redirect_to(redirect_path)
    end

    context 'when document is already associated' do
      before { company.documents << document }

      it 'does not associate document' do
        post :create, params: { workbench_id: workbench.id, company_id: company.id, document_id: document.id }
        expect(company.reload.documents).to eq([document])
        expect(flash[:error]).to be_present
        expect(response).to redirect_to(redirect_path)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:document_membership) { company.document_memberships.first }

    before do
      allow(Policy::Authorizer::Controller).to receive(:default_class).and_return(Policy::Authorizer::PermitAll)
      company.documents << document
    end

    it 'destroys document association' do
      delete :destroy, params: { workbench_id: workbench.id, company_id: company.id, id: document_membership.id }
      expect(company.reload.documents).to eq([])
      expect(flash[:success]).to be_present
      expect(response).to redirect_to(redirect_path)
    end

    context 'when document is not associatied' do
      let(:other_company) { context.company(:other_company) }
      let(:document_membership) do
        other_company.documents << unassociated_document
        other_company.document_memberships.last
      end

      it 'is not found' do
        expect(
          delete(:destroy, params: { workbench_id: workbench.id, company_id: company.id, id: document_membership.id })
        ).to render_template('errors/not_found')
      end
    end
  end
end
