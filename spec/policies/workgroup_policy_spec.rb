RSpec.describe WorkgroupPolicy, type: :pundit_policy do

  let( :record ){ build_stubbed :workgroup }

  permissions :create? do
    it "should not allow for creation" do
      expect_it.not_to permit(user_context, record)
    end
  end

  permissions :update? do
    it "should not allow for update" do
      expect_it.not_to permit(user_context, record)
    end

    context "for the owner" do
      before do
        record.owner = user.organisation
      end

      it "should not allow for update" do
        expect_it.not_to permit(user_context, record)
      end

      context "with the permission" do
        it "should allow for update" do
          add_permissions('workgroups.update', to_user: user)
          expect_it.to permit(user_context, record)
        end
      end
    end
  end

  permissions :destroy? do
    it "should not allow for destroy" do
      expect_it.not_to permit(user_context, record)
    end

    context "for the owner" do
      before do
        record.owner = user.organisation
      end

      it "should not allow for destroy" do
        expect_it.not_to permit(user_context, record)
      end

      context "with the permission" do
        it "should allow for destroy" do
          add_permissions('workgroups.destroy', to_user: user)
          expect_it.to permit(user_context, record)
        end
      end
    end
  end

end
