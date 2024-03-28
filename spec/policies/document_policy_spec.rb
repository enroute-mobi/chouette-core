RSpec.describe DocumentPolicy, type: :pundit_policy do
  let(:context) do
    Chouette.create do
      organisation(:owner_organisation) { user :owner }
      organisation(:document_organisation) { user :document_user }
      organisation(:another_organisation) { user :another }
      workgroup owner: :owner_organisation do
        workbench :document_workbench, organisation: :user_organisation do
          document
        end
        workbench :owner_workbench, organisation: :owner_organisation
        workbench :another_workbench, organisation: :another_organisation
      end
    end
  end

  let(:owner_user) { context.user(:owner) }
  let(:document_user) { context.user(:document_user) }
  let(:another_user) { context.user(:another) }
  let(:owner_workbench) { context.workbench(:owner_workbench) }
  let(:document_workbench) { context.workbench(:document_workbench) }
  let(:another_workbench) { context.workbench(:another_workbench) }

  subject { described_class.new UserContext.new(user, workbench: workbench), context.document }

  describe 'for edit and update actions' do
    context 'when user is Workgroup owner and has the permission "documents.update"' do
      let(:user) { owner_user }
      let(:workbench) { owner_workbench }

      before { user.permissions << 'documents.update' }

      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
    end

    context 'when user belongs to the same organisation than document and has the permission "documents.update"' do
      let(:user) { document_user }
      let(:workbench) { document_workbench }
      before { user.permissions << 'documents.update' }

      it { is_expected.to permit_action(:edit) }
      it { is_expected.to permit_action(:update) }
    end

    context 'when user does not belong to the same organisation than document and has the permission "documents.update"' do
      let(:user) { another_user }
      let(:workbench) { another_workbench }
      before { user.permissions << 'documents.update' }

      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
    end
  end

  describe 'for destroy action' do
    context 'when user is Workgroup owner and has the permission "documents.destroy"' do
      let(:user) { owner_user }
      let(:workbench) { owner_workbench }

      before { user.permissions << 'documents.destroy' }

      it { is_expected.to forbid_action(:destroy) }
    end

    context 'when user belongs to the same organisation than document and has the permission "documents.destroy"' do
      let(:user) { document_user }
      let(:workbench) { document_workbench }
      before { user.permissions << 'documents.destroy' }

      it { is_expected.to permit_action(:destroy) }
    end

    context 'when user does not belong to the same organisation than document and has the permission "documents.destroy"' do
      let(:user) { another_user }
      let(:workbench) { another_workbench }
      before { user.permissions << 'documents.destroy' }

      it { is_expected.to forbid_action(:destroy) }
    end
  end
end
