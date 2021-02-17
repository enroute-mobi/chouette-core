RSpec.describe WorkbenchPolicy, type: :policy do

    permissions :show? do
      let( :record ){ build_stubbed :workbench }

      it "should not allow show" do
        expect_it.not_to permit(user_context, record)
      end

      context "when user belongs to workbench's workgroup organisations" do
        before do
          allow(record.workgroup.organisations).to receive(:exists?).with(id: user.organisation_id) { true }
        end

        it "should allow show" do
          expect_it.to permit(user_context, record)
        end

      end
    end

    permissions :update? do
      let(:record) { build_stubbed :workbench, organisation: user.organisation }

      context "without permission" do
        it "should not allow update" do
          remove_permissions('workbenches.update', from_user: user)
          expect_it.not_to permit(user_context, record)
        end
      end

      context "with permission" do
        it "should allow update" do
          add_permissions('workbenches.update', to_user: user)
          expect_it.to permit(user_context, record)
        end
      end

    end

end
