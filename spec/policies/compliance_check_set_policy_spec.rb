RSpec.describe ComplianceCheckSetPolicy, type: :policy do

  let(:record) { create :compliance_check_set }
  before(:each) { user.organisation = create(:organisation) }

  context "when the workbench belongs to another organisation (other workgroup)" do
    permissions :show? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
  end

  context "when the workbench belongs to another organisation (same workgroup)" do
    before do
      allow(user.workgroups).to receive(:pluck).with(:id).and_return [record.workbench.workgroup_id]
    end

    permissions :show? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
  end

  context "when the workbench belongs to another organisation (same workgroup) but i am the owner of the workgroup" do
    before do
      record.workbench.workgroup.update owner_id: user.organisation_id
      allow(user.workgroups).to receive(:pluck).with(:id).and_return [record.workbench.workgroup_id]
    end

    permissions :show? do
      it "allows user" do
        expect_it.to permit(user_context, record)
      end
    end
  end

  context "when the workbench belongs to the same organisation" do
    before do
      user.organisation.workbenches << record.workbench
    end

    permissions :show? do
      it "allows user" do
        expect_it.to permit(user_context, record)
      end
    end
  end

  context "when the CCS workgroup belongs to the same organisation" do
    let(:new_workbench) { create :workbench, workgroup: record.workgroup }
    before do
      user.organisation.workbenches << new_workbench
    end

    permissions :show? do
      it "allows user" do
        expect_it.to permit(user_context, record)
      end
    end
  end
end
