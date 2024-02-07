RSpec.describe WorkgroupWorkbenchPolicy, type: :pundit_policy do
  let(:context) do
    Chouette.create do
      organisation(:owner_organisation) { user :owner }
      organisation(:workbench_organisation) { user :workbench_user }
      workgroup owner: :owner_organisation do
        workbench organisation: :workbench_organisation
      end
    end
  end

  let(:workbench) { context.workbench }
  let(:owner_user) { context.user(:owner) }
  let(:workbench_user) { context.user(:workbench_user) }

  subject { described_class.new UserContext.new(user), workbench }

  describe "create action" do
    subject { described_class.new UserContext.new(user, workgroup: workbench.workgroup), Workbench }

    context 'when user is Workgroup owner' do
      let(:user) { owner_user }

      context 'with the permission "workbenches.create"' do
        before { user.permissions << 'workbenches.create' }
        it { is_expected.to permit_action(:create) }
      end

      context 'without the permission "workbenches.create"' do
        before { user.permissions.delete 'workbenches.create' }
        it { is_expected.to_not permit_action(:create) }
      end
    end

    context 'when user is not Workgroup owner' do
      let(:user) { workbench_user }

      context 'with the permission "workbenches.create"' do
        before { user.permissions << 'workbenches.create' }
        it { is_expected.to_not permit_action(:create) }
      end

      context 'with the permission "workbenches.update"' do
        before { user.permissions << 'workbenches.update' }
        it { is_expected.to_not permit_action(:update) }
      end
    end
  end

  context 'when user is Workgroup owner' do
    let(:user) { owner_user }

    context 'with the permission "workbenches.update"' do
      before { user.permissions << 'workbenches.update' }
      it { is_expected.to permit_action(:update) }
    end

    context 'without the permission "workbenches.update"' do
      before { user.permissions.delete 'workbenches.update' }
      it { is_expected.to_not permit_action(:update) }
    end

    it { is_expected.to_not permit_action(:destroy) }
  end

  context 'when user is not Workgroup owner' do
    let(:user) { workbench_user }

    it { is_expected.to permit_action(:show) }

    context 'with the permission "workbenches.update"' do
      before { user.permissions << 'workbenches.update' }
      it { is_expected.to_not permit_action(:update) }
    end

    it { is_expected.to_not permit_action(:destroy) }
  end

  context 'when user is not member of the Workgroup' do
    let(:other_context) { Chouette.create { user } }
    let(:user) { other_context.user }

    it { is_expected.to_not permit_action(:show) }
  end
end
