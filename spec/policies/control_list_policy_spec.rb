# frozen_string_literal: true

RSpec.describe ControlListPolicy, type: :policy do
  let(:context) do
    Chouette.create do
      organisation(:user_organisation) { user :workbench_user }
      workbench :control_list_workbench, organisation: :user_organisation

      organisation(:another_organisation) { user :another_user }
      workbench :another_workbench, organisation: :another_organisation
    end
  end

  let(:control_list) { context.workbench(:control_list_workbench).control_lists.create! name: 'Test' }

  subject { described_class.new UserContext.new(user, workbench: workbench), control_list }

  describe 'for edit and update actions' do
    context 'when user belongs to the same workbench than control list and has the permission "control_lists.update"' do
      let(:user) { context.user(:workbench_user) }
      let(:workbench) { context.workbench(:control_list_workbench) }
      before { user.permissions << 'control_lists.update' }

      it { is_expected.to permit_action(:edit) }
      it { is_expected.to permit_action(:update) }
    end

    context 'when user does not belong to the same workbench than control list and has the permission "control_lists.update"' do
      let(:user) { context.user(:another_user) }
      let(:workbench) { context.workbench(:another_workbench) }
      before { user.permissions << 'control_lists.update' }

      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
    end
  end

  describe 'for destroy action' do
    context 'when user belongs to the same workbench than control list and has the permission "control_lists.destroy"' do
      let(:user) { context.user(:workbench_user) }
      let(:workbench) { context.workbench(:control_list_workbench) }
      before { user.permissions << 'control_lists.destroy' }

      it { is_expected.to permit_action(:destroy) }
    end

    context 'when user belongs to the same workbench than control list and has the permission "control_lists.destroy" but control list is linked with a processing rule' do
      let(:user) { context.user(:workbench_user) }
      let(:workbench) { context.workbench(:control_list_workbench) }
      before do
        user.permissions << 'control_lists.destroy'
        workbench.processing_rules.create! operation_step: 'after_import',
                                           processable: control_list
      end

      it { is_expected.to forbid_action(:destroy) }
    end

    context 'when user does not belong to the same workbench than control list and has the permission "control_lists.destroy"' do
      let(:user) { context.user(:another_user) }
      let(:workbench) { context.workbench(:another_workbench) }
      before { user.permissions << 'control_lists.destroy' }

      it { is_expected.to forbid_action(:destroy) }
    end
  end
end
