RSpec.describe AccessLinkPolicy, type: :policy do

  let( :record ){ build_stubbed :access_link }

  permissions :create? do
    it_behaves_like 'permitted policy and same organisation', "access_links.create", archived: true
  end
  permissions :destroy? do
    it_behaves_like 'permitted policy and same organisation', "access_links.destroy", archived: true
  end
  permissions :edit? do
    it_behaves_like 'permitted policy and same organisation', "access_links.update", archived: true
  end
  permissions :new? do
    it_behaves_like 'permitted policy and same organisation', "access_links.create", archived: true
  end
  permissions :update? do
    it_behaves_like 'permitted policy and same organisation', "access_links.update", archived: true
  end
end
