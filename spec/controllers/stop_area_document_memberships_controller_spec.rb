# frozen_string_literal: true

RSpec.describe StopAreaDocumentMembershipsController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      workgroup do
        document_type :document_type

        workbench organisation: Organisation.find_by(code: 'first') do
          document_provider :document_provider

          stop_area :stop_area1
          stop_area :other_stop_area

          document :document, document_type: :document_type, document_provider: :document_provider
          document :unassociated_document, document_type: :document_type, document_provider: :document_provider
        end
      end
    end
  end

  let(:workbench) { context.workbench }
  let(:stop_area) { context.stop_area(:stop_area1) }
  let(:redirect_path) { workbench_stop_area_referential_stop_area_document_memberships_path(workbench, stop_area) }

  let(:document) { context.document(:document) }
  let(:unassociated_document) { context.document(:unassociated_document) }

  let(:stop_area_policy_update) { true }
  let(:stop_area_policy) { double(update: stop_area_policy_update) }
  let(:document_membership_policy) { double }

  describe 'GET #index' do
    let(:user_can_create_document_memberships) { true }
    let(:user_can_update_stop_areas) { true }
    let(:request) { get :index, params: { workbench_id: workbench.id, stop_area_id: stop_area.id } }

    before do
      stop_area.documents << document
      unassociated_document

      fk_policy = double
      allow(fk_policy).to receive(:create?).with(DocumentMembership).and_return(user_can_create_document_memberships)
      allow(fk_policy).to receive(:update?).and_return(user_can_update_stop_areas)
      expect(controller).to receive(:parent_policy).at_least(1).and_return(fk_policy)

      request
    end

    context 'when user cannot create document memberships' do
      let(:user_can_create_document_memberships) { false }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when user cannot update stop areas' do
      let(:user_can_update_stop_areas) { false }

      it 'does not return unassociated documents' do
        expect(assigns(:document_memberships).map(&:document)).to eq([document])
        expect(assigns(:unassociated_documents).map(&:document)).to eq([])
      end
    end

    context 'when user can update stop areas' do
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
      post :create, params: { workbench_id: workbench.id, stop_area_id: stop_area.id, document_id: document.id }
      expect(stop_area.reload.documents).to eq([document])
      expect(flash[:success]).to be_present
      expect(response).to redirect_to(redirect_path)
    end

    context 'when document is already associated' do
      before { stop_area.documents << document }

      it 'does not associate document' do
        post :create, params: { workbench_id: workbench.id, stop_area_id: stop_area.id, document_id: document.id }
        expect(stop_area.reload.documents).to eq([document])
        expect(flash[:error]).to be_present
        expect(response).to redirect_to(redirect_path)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:document_membership) { stop_area.document_memberships.first }

    before do
      allow(Policy::Authorizer::Controller).to receive(:default_class).and_return(Policy::Authorizer::PermitAll)
      stop_area.documents << document
    end

    it 'destroys document association' do
      delete :destroy, params: { workbench_id: workbench.id, stop_area_id: stop_area.id, id: document_membership.id }
      expect(stop_area.reload.documents).to eq([])
      expect(flash[:success]).to be_present
      expect(response).to redirect_to(redirect_path)
    end

    context 'when document is not associatied' do
      let(:other_stop_area) { context.stop_area(:other_stop_area) }
      let(:document_membership) do
        other_stop_area.documents << unassociated_document
        other_stop_area.document_memberships.last
      end

      it 'is not found' do
        expect(
          delete(
            :destroy,
            params: { workbench_id: workbench.id, stop_area_id: stop_area.id, id: document_membership.id }
          )
        ).to render_template('errors/not_found')
      end
    end
  end
end
