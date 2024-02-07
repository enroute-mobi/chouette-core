RSpec.describe LoginPolicy, type: :pundit_policy do
  permissions :boiv? do
    it 'no permission starting with boiv:. →  denies' do
      expect( LoginPolicy.new(user_context.user) ).not_to be_boiv
    end

    with_user_permission 'boiv:anything' do
      it { expect( LoginPolicy.new(user_context.user) ).to be_boiv }
    end
    with_user_permission 'boiv:' do
      it { expect( LoginPolicy.new(user_context.user) ).not_to be_boiv }
    end
  end

end
