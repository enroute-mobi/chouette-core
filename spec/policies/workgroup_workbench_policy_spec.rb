RSpec.describe WorkgroupWorkbenchPolicy, type: :policy do

  let( :record ){ build_stubbed :workbench }

    permissions :create? do
      it "should not allow for creation" do
        expect_it.not_to permit(user_context, record)
      end
    end

    permissions :update? do
      it "should not allow for update" do
        expect_it.not_to permit(user_context, record)
      end

      context "for the workgroup owner" do
        before do
          record.workgroup.owner = user.organisation
        end

        it "should not allow for update" do
          expect_it.not_to permit(user_context, record)
        end

        context "with the permission" do
          it "should allow for update" do
            add_permissions('workbenches.update', to_user: user)
            expect_it.to permit(user_context, record)
          end
        end
      end
    end

    permissions :destroy? do
      it "should not allow for destroy" do
        expect_it.not_to permit(user_context, record)
      end
    end
end
