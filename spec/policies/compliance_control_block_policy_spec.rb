
RSpec.describe ComplianceControlBlockPolicy do

  let( :record ){ build_stubbed :compliance_control_block }
  before { stub_policy_scope(record) }

  permissions :create? do
    it_behaves_like 'permitted policy outside referential', 'compliance_control_blocks.create'
  end

  permissions :update? do
    it_behaves_like 'permitted policy outside referential', 'compliance_control_blocks.update'
  end

  permissions :destroy? do
    it_behaves_like 'permitted policy outside referential', 'compliance_control_blocks.destroy'
  end
end
