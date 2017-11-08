RSpec.describe Api::V1::ComplianceCheckSetsController, type: :controller do
  include_context 'iboo authenticated api user'

  describe "POST #validate" do
    it "calls #update_status on the ComplianceCheckSet" do
      check_set = create(:compliance_check_set)
      expect_any_instance_of(ComplianceCheckSet).to receive(:update_status)

      patch :validated, id: check_set.id
    end
  end
end
