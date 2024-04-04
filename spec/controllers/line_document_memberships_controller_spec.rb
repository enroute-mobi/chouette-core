# frozen_string_literal: true

RSpec.describe LineDocumentMembershipsController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      workgroup do
        document_type :document_type

        workbench organisation: Organisation.find_by(code: 'first') do
          document_provider :document_provider

          line :line1, name: 'Line one', published_name: 'First Line', number: 'L1'
          line :other_line

          document :document, document_type: :document_type, document_provider: :document_provider
          document :unassociated_document, document_type: :document_type, document_provider: :document_provider
        end
      end
    end
  end

  let(:workbench) { context.workbench }
  let(:line) { context.line(:line1) }
  let(:redirect_path) { workbench_line_referential_line_document_memberships_path(workbench, line) }

  let(:document) { context.document(:document) }
  let(:unassociated_document) { context.document(:unassociated_document) }

  let(:line_policy_update) { true }
  let(:line_policy) { double(update: line_policy_update) }
  let(:document_membership_policy) { double }

  describe 'GET #index' do
    let(:user_can_create_document_memberships) { true }
    let(:user_can_update_lines) { true }
    let(:request) { get :index, params: { workbench_id: workbench.id, line_id: line.id } }

    before do
      line.documents << document
      unassociated_document

      fk_policy = double
      allow(fk_policy).to receive(:create?).with(DocumentMembership).and_return(user_can_create_document_memberships)
      allow(fk_policy).to receive(:update?).and_return(user_can_update_lines)
      expect(controller).to receive(:parent_policy).at_least(1).and_return(fk_policy)

      request
    end

    context 'when user cannot create document memberships' do
      let(:user_can_create_document_memberships) { false }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when user cannot update lines' do
      let(:user_can_update_lines) { false }

      it 'does not return unassociated documents' do
        expect(assigns(:document_memberships).map(&:document)).to eq([document])
        expect(assigns(:unassociated_documents).map(&:document)).to eq([])
      end
    end

    context 'when user can update lines' do
      it 'returns unassociated documents' do
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
      post :create, params: { workbench_id: workbench.id, line_id: line.id, document_id: document.id }
      expect(line.reload.documents).to eq([document])
      expect(flash[:success]).to be_present
      expect(response).to redirect_to(redirect_path)
    end

    context 'when document is already associated' do
      before { line.documents << document }

      it 'does not associate document' do
        post :create, params: { workbench_id: workbench.id, line_id: line.id, document_id: document.id }
        expect(line.reload.documents).to eq([document])
        expect(flash[:error]).to be_present
        expect(response).to redirect_to(redirect_path)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:document_membership) { line.document_memberships.first }

    before do
      allow(Policy::Authorizer::Controller).to receive(:default_class).and_return(Policy::Authorizer::PermitAll)
      line.documents << document
    end

    it 'destroys document association' do
      delete :destroy, params: { workbench_id: workbench.id, line_id: line.id, id: document_membership.id }
      expect(line.reload.documents).to eq([])
      expect(flash[:success]).to be_present
      expect(response).to redirect_to(redirect_path)
    end

    context 'when document is not associatied' do
      let(:other_line) { context.line(:other_line) }
      let(:document_membership) do
        other_line.documents << unassociated_document
        other_line.document_memberships.last
      end

      it 'is not found' do
        expect(
          delete(:destroy, params: { workbench_id: workbench.id, line_id: line.id, id: document_membership.id })
        ).to render_template('errors/not_found')
      end
    end
  end
end
