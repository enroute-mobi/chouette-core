RSpec.describe Chouette::RoutePolicy, type: :pundit_policy do

  let( :record ){ build_stubbed :route }

  permissions :create? do
    it_behaves_like 'permitted policy and same organisation', 'routes.create', archived_and_finalised: true
  end

  permissions :duplicate? do
    it_behaves_like 'permitted policy and same organisation', 'routes.create', archived_and_finalised: true
  end

  permissions :destroy? do
    it_behaves_like 'permitted policy and same organisation', 'routes.destroy', archived_and_finalised: true
  end

  permissions :edit? do
    it_behaves_like 'permitted policy and same organisation', 'routes.update', archived_and_finalised: true
  end

  permissions :new? do
    it_behaves_like 'permitted policy and same organisation', 'routes.create', archived_and_finalised: true
  end

  permissions :update? do
    it_behaves_like 'permitted policy and same organisation', 'routes.update', archived_and_finalised: true
  end
end
