
RSpec.describe ComplianceControlPolicy do

  let( :record ){ build_stubbed :compliance_control }
  before { stub_policy_scope(record) }

  permissions :create? do
    it_behaves_like 'permitted policy outside referential', 'compliance_controls.create'
  end

  context "when the user can update the parent control set" do
    before(:each){
      allow_any_instance_of(ComplianceControlSetPolicy).to receive(:update?).and_return(true)
    }

    permissions :update? do
      it_behaves_like 'permitted policy outside referential', 'compliance_controls.update'
    end

    permissions :destroy? do
      it_behaves_like 'permitted policy outside referential', 'compliance_controls.destroy'
    end
  end

  context "when the user cannot update the parent control set" do
    before(:each){
      allow_any_instance_of(ComplianceControlSetPolicy).to receive(:update?).and_return(false)
    }

    permissions :update? do
      it_behaves_like 'always forbidden', 'compliance_controls.update'
    end

    permissions :destroy? do
      it_behaves_like 'always forbidden', 'compliance_controls.destroy'
    end
  end
end
