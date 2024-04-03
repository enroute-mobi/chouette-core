RSpec.describe ApplicationPolicy, type: :pundit_policy do

  permissions :organisation_match? do

    it "denies a user with a different organisation" do
      expect_it.not_to permit(user_context, referential)
    end

    it "allows a user with a different organisation" do
      user.organisation = referential.organisation
      expect_it.to permit(user_context, referential)
    end
  end

end
