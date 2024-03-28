RSpec.describe JourneyPatternPolicy, type: :pundit_policy do

  let( :record ){ build_stubbed :journey_pattern }

  permissions :create? do
      it_behaves_like 'permitted policy and same organisation', "journey_patterns.create", archived_and_finalised: true
  end
  permissions :destroy? do
      it_behaves_like 'permitted policy and same organisation', "journey_patterns.destroy", archived_and_finalised: true
  end
  permissions :edit? do
      it_behaves_like 'permitted policy and same organisation', "journey_patterns.update", archived_and_finalised: true
  end
  permissions :new? do
      it_behaves_like 'permitted policy and same organisation', "journey_patterns.create", archived_and_finalised: true
  end
  permissions :update? do
      it_behaves_like 'permitted policy and same organisation', "journey_patterns.update", archived_and_finalised: true
  end
end
