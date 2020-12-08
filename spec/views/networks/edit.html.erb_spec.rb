describe "/networks/edit", :type => :view do

  let(:context) do
    Chouette.create { network }
  end

  let!(:workbench) { assign :workbench, context.workbench }
  let!(:network) { assign :network, context.network }

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
