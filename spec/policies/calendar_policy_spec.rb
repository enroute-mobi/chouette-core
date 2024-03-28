# frozen_string_literal: true

RSpec.describe CalendarPolicy, type: :pundit_policy do
  let(:workbench) { build_stubbed(:workbench) }
  let(:user_context) { create_user_context(user, referential, workbench) }
  let(:record) { build_stubbed(:calendar) }

  before { stub_policy_scope(record) }

  permissions :new? do
    it_behaves_like 'permitted policy', 'calendars.create'
  end

  permissions :create? do
    it_behaves_like 'permitted policy', 'calendars.create'
  end

  permissions :edit? do
    it_behaves_like 'permitted policy and same workbench', 'calendars.update'
  end

  permissions :update? do
    it_behaves_like 'permitted policy and same workbench', 'calendars.update'
  end

  permissions :destroy? do
    it_behaves_like 'permitted policy and same workbench', 'calendars.destroy'
  end

  permissions :share? do
    it_behaves_like 'permitted policy and same workbench', 'calendars.share'
  end
end
