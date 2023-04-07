# frozen_string_literal: true

RSpec.describe MacroListPolicy, type: :policy do
  let(:context) do
    Chouette.create do
      organisation(:user_organisation) { user :workbench_user }
      workbench :macro_list_workbench, organisation: :user_organisation
    end
  end

  let(:macro_list) { context.workbench(:macro_list_workbench).macro_lists.create! name: 'Test' }

  subject { described_class.new UserContext.new(user, workbench: workbench), macro_list }

  describe 'for edit and update actions' do
    context 'when user belongs to the same workbench than macro list and has the permission "macro_lists.update"' do
      let(:user) { context.user(:workbench_user) }
      let(:workbench) { context.workbench(:macro_list_workbench) }
      before { user.permissions << 'macro_lists.update' }

      it { is_expected.to permit_action(:edit) }
      it { is_expected.to permit_action(:update) }
    end
  end

  describe 'for destroy action' do
    context 'when user belongs to the same workbench than macro list and has the permission "macro_lists.destroy"' do
      let(:user) { context.user(:workbench_user) }
      let(:workbench) { context.workbench(:macro_list_workbench) }
      before do
        user.permissions << 'macro_lists.destroy'
        workbench.processing_rules.create! operation_step: 'after_import',
                                           processable: macro_list
      end

      it { is_expected.to forbid_action(:destroy) }
    end

    context 'when user belongs to the same workbench than macro list and has the permission "macro_lists.destroy" but control list is linked with a processing rule' do
      let(:user) { context.user(:workbench_user) }
      let(:workbench) { context.workbench(:macro_list_workbench) }
      before do
        user.permissions << 'macro_lists.destroy'
      end

      it { is_expected.to permit_action(:destroy) }
    end
  end
end
