RSpec.describe WorkbenchPolicy, type: :policy do

    permissions :show? do
      let( :record ){ build_stubbed :workbench }

      it "should not allow show" do
        expect_it.not_to permit(user_context, record)
      end

      context "when user belongs to workbench organisation" do
        before do
          allow(record).to receive(:organisation_id) { user.organisation_id }
          # allow(record.workgroup.organisations).to receive(:exists?).with(id: user.organisation_id) { true }
        end

        it "should allow show" do
          expect_it.to permit(user_context, record)
        end

      end
    end

end
