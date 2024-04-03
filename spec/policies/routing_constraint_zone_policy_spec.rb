RSpec.describe RoutingConstraintZonePolicy, type: :pundit_policy do

  let( :record ){ build_stubbed :routing_constraint_zone }


  permissions :create? do
    it_behaves_like 'permitted policy and same organisation', 'routing_constraint_zones.create', archived_and_finalised: true
  end

  permissions :destroy? do
    it_behaves_like 'permitted policy and same organisation', 'routing_constraint_zones.destroy', archived_and_finalised: true
  end

  permissions :edit? do
    it_behaves_like 'permitted policy and same organisation', 'routing_constraint_zones.update', archived_and_finalised: true
  end

  permissions :new? do
    it_behaves_like 'permitted policy and same organisation', 'routing_constraint_zones.create', archived_and_finalised: true
  end

  permissions :update? do
    it_behaves_like 'permitted policy and same organisation', 'routing_constraint_zones.update', archived_and_finalised: true
  end
end
