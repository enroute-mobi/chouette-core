RSpec.describe LineReferentialPolicy, type: :pundit_policy do

  let(:context) do
    Chouette.create do
      organisation(:owner_organisation) { user :owner }
      organisation { user :another }
      workgroup owner: :owner_organisation
    end
  end

  let(:line_referential) { context.workgroup.line_referential }
  let(:owner_user) { context.user(:owner) }
  let(:another_user) { context.user(:another) }

  subject { described_class.new UserContext.new(user), line_referential }

  describe "for edit and update actions" do
    context 'when user is Workgroup owner and has the permission "line_referentials.update"' do
      let(:user) { owner_user }
      before { user.permissions << 'line_referentials.update' }

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
      before { user.permissions << 'line_referentials.update' }

      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
    end
  end

  describe "for synchronize action" do
    context 'when user is Workgroup owner and has the permission "line_referentials.synchronize"' do
      let(:user) { owner_user }
      before { user.permissions << 'line_referentials.synchronize' }

      it { is_expected.to permit_action(:synchronize) }
    end

    context 'when user is Workgroup owner without the permission' do
      let(:user) { owner_user }
      before { user.permissions.clear }

      it { is_expected.to forbid_action(:synchronize) }
    end

    context "when user isn't Workgroup owner with the permission" do
      let(:user) { another_user }
      before { user.permissions << 'line_referentials.synchronize' }

      it { is_expected.to forbid_action(:synchronize) }
    end
  end

end
