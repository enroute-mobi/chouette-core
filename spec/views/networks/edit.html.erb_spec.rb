
describe "/networks/edit", :type => :view do

  let!(:network) { assign(:network, create(:network) ) }
  let!(:line_referential) { assign :line_referential, network.line_referential }

  before :each do
    allow(view).to receive(:resource_class).and_return(Chouette::Network)
  end

  describe "form" do
    it "should render input for name" do
      render
      expect(rendered).to have_selector("form") do
        with_tag "input[type=text][name='network[name]'][value=?]", network.name
      end
    end

  end
end
