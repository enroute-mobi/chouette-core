
describe "/networks/new", :type => :view do

  let!(:network) {  assign(:network, build(:network)) }
  let!(:line_referential) { assign :line_referential, network.line_referential }

  describe "form" do
    it "should render input for name" do
      allow(view).to receive(:resource_class).and_return(Chouette::Network)
      render
      expect(rendered).to have_selector("form") do
        with_selector "input[type=text][name=?]", network.name
      end
    end

  end
end
