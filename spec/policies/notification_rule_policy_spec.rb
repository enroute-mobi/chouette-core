RSpec.describe NotificationRulePolicy, type: :pundit_policy do

  let( :record ){ build_stubbed :notification_rule }

  context "when notification rule belongs to user's workbench" do
    before do
      allow(NotificationRule).to receive(:where).with(workbench_id: [record.workbench_id]).and_return double("instance of #{NotificationRule}").as_null_object

      %w(create update destroy).each do |action|
        add_permissions("notification_rules.#{action}", to_user: user)
      end
      allow(user).to receive(:workbench_ids).and_return([record.workbench_id])
    end
    permissions :show? do
      it "allows user" do
        expect_it.to permit(user_context, record)
      end
    end
    permissions :create? do
      it "allows user" do
        expect_it.to permit(user_context, record)
      end
    end
    permissions :destroy? do
      it "allows user" do
        expect_it.to permit(user_context, record)
      end
    end
    permissions :update? do
      it "allows user" do
        expect_it.to permit(user_context, record)
      end
    end
  end

  context "when notification rule doesn't belong to user's workbench" do
    before(:each) do
      user_context.context[:workbench] = nil
    end
    permissions :show? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
    permissions :create? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
    permissions :destroy? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
    permissions :update? do
      it "denies user" do
        expect_it.not_to permit(user_context, record)
      end
    end
  end
end
