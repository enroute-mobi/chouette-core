RSpec.describe Api::V1::ComplianceCheckSetsController, type: :controller do
  include_context 'iboo authenticated api user'

  describe "POST #validate" do
    let(:check_set) { create(:compliance_check_set) }

    it "calls #update_status on the ComplianceCheckSet" do
      expect_any_instance_of(ComplianceCheckSet).to receive(:update_status)

      patch :validated, id: check_set.id
    end

    context "responds with" do
      render_views

      it "object JSON on #update_status true" do
        allow_any_instance_of(
          ComplianceCheckSet
        ).to receive(:update_status).and_return(true)

        patch :validated, id: check_set.id

        expect(JSON.parse(response.body)['id']).to eq(check_set.id)
      end

      it "error JSON on #update_status false" do
        allow_any_instance_of(
          ComplianceCheckSet
        ).to receive(:update_status).and_return(false)

        patch :validated, id: check_set.id

        expect(response.body).to include('error')
      end
    end
  end
end
