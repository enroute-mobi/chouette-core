RSpec.describe StopAreaReferentialPolicy, type: :pundit_policy do

  let(:context) do
    Chouette.create do
      organisation(:owner_organisation) { user :owner }
      organisation { user :another }
      workgroup owner: :owner_organisation
    end
  end

  let(:stop_area_referential) { context.workgroup.stop_area_referential }
  let(:owner_user) { context.user(:owner) }
  let(:another_user) { context.user(:another) }

  subject { described_class.new UserContext.new(user), stop_area_referential }

  describe "for edit and update actions" do
    context 'when user is Workgroup owner and has the permission "stop_area_referentials.update"' do
      let(:user) { owner_user }
      before { user.permissions << 'stop_area_referentials.update' }

      it { is_expected.to permit_action(:edit) }
      it { is_expected.to permit_action(:update) }
    end

    context 'when user is Workgroup owner without the permission' do
      let(:user) { owner_user }
      before { user.permissions.clear }

      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
    end

    context "when user isn't Workgroup owner with the permission" do
      let(:user) { another_user }
      before { user.permissions << 'stop_area_referentials.update' }

      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
    end
  end
end
