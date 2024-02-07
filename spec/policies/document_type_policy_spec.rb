RSpec.describe DocumentTypePolicy, type: :pundit_policy do
  subject { described_class.new UserContext.new(user, workgroup: workgroup), document_type }

  describe 'for edit and update actions' do
    let(:context) do
      Chouette.create do
        organisation(:owner_organisation) { user :owner }
        organisation(:another_organisation) { user :another }
        workgroup :owner_workgroup, owner: :owner_organisation do
          document_type
        end

        workgroup :another_workgroup, owner: :another_organisation
      end
    end

    let(:owner_user) { context.user(:owner) }
    let(:another_user) { context.user(:another) }
    let(:owner_workgroup) { context.workgroup(:owner_workgroup) }
    let(:another_workgroup) { context.workgroup(:another_workgroup) }
    let(:document_type) { context.document_type }

    context 'when user is Workgroup owner and has the permission "document_types.update"' do
      let(:user) { owner_user }
      let(:workgroup) { owner_workgroup }

      before { user.permissions << 'document_types.update' }

      it { is_expected.to permit_action(:edit) }
      it { is_expected.to permit_action(:update) }
    end

    context 'when user does not belong to the same organisation than document and has the permission "document_types.update"' do
      let(:user) { another_user }
      let(:workgroup) { another_workgroup }
      before { user.permissions << 'document_types.update' }

      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
    end
  end

  describe 'for destroy action' do
    context 'when document_type has no documents' do
      let(:context) do
        Chouette.create do
          organisation(:owner_organisation) { user :owner }
          organisation(:another_organisation) { user :another }
          workgroup :owner_workgroup, owner: :owner_organisation do
            document_type
          end

          workgroup :another_workgroup, owner: :another_organisation
        end
      end

      let(:owner_user) { context.user(:owner) }
      let(:another_user) { context.user(:another) }
      let(:owner_workgroup) { context.workgroup(:owner_workgroup) }
      let(:another_workgroup) { context.workgroup(:another_workgroup) }
      let(:document_type) { context.document_type }

      context 'when user is Workgroup owner and has the permission "document_types.destroy"' do
        let(:user) { owner_user }
        let(:workgroup) { owner_workgroup }

        before do
          user.permissions << 'document_types.destroy'
        end

        it { is_expected.to permit_action(:destroy) }
      end

      context 'when user does not belong to the same organisation than document and has the permission "document_types.destroy"' do
        let(:user) { another_user }
        let(:workgroup) { another_workgroup }
        before do
          user.permissions << 'document_types.destroy'
        end

        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context 'when document_type has documents' do
      let(:context) do
        Chouette.create do
          organisation(:owner_organisation) { user :owner }
          workgroup :owner_workgroup, owner: :owner_organisation do
            document_type :test
            document document_type: :test
          end
        end
      end

      let(:owner_user) { context.user(:owner) }
      let(:owner_workgroup) { context.workgroup(:owner_workgroup) }
      let(:document_type) { context.document.document_type }

      context 'when user is Workgroup owner and has the permission "document_types.destroy"' do
        let(:user) { owner_user }
        let(:workgroup) { owner_workgroup }

        before do
          user.permissions << 'document_types.destroy'
        end

        it { is_expected.to forbid_action(:destroy) }
      end
    end
  end
end
