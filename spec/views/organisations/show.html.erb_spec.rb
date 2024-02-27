RSpec.describe "/organisations/show", type: :view do
  assign_organisation

  let(:organisation) { first_organisation }
  let!(:user) { create :user,  organisation: first_organisation }
  let!(:search) { assign :q, Ransack::Search.new(User) }
  let!(:users) { assign :users, organisation.users.paginate(page: 1) }

  before do
    allow(view).to receive(:resource){ organisation }
    allow(view).to receive(:resource_class){ organisation.class }
    allow(view).to receive(:parent_for_parent_policy) { user }
  end

  it "should render each User" do
    render
    organisation.users.each do |user|
      expect(rendered).to have_selector("tr.user td.name", :text => user.name)
    end
  end

end
