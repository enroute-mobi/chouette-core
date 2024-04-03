RSpec.describe TimeTablePolicy, type: :pundit_policy do

  let( :record ){ build_stubbed :time_table }

  permissions :create? do
    it_behaves_like 'permitted policy and same organisation', 'time_tables.create', archived_and_finalised: true
  end

  permissions :destroy? do
    it_behaves_like 'permitted policy and same organisation', 'time_tables.destroy', archived_and_finalised: true
  end

  permissions :edit? do
    it_behaves_like 'permitted policy and same organisation', 'time_tables.update', archived_and_finalised: true
  end

  permissions :new? do
    it_behaves_like 'permitted policy and same organisation', 'time_tables.create', archived_and_finalised: true
  end

  permissions :update? do
    it_behaves_like 'permitted policy and same organisation', 'time_tables.update', archived_and_finalised: true
  end
end
