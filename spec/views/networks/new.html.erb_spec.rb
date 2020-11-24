describe "/networks/new", type: :view do

  let(:context) { Chouette.create { line_provider } }

  let!(:workbench) { assign :workbench, context.workbench }
  let!(:line_referential) { assign :line_referential, context.line_referential }

  let!(:network) { assign :network, context.line_provider.networks.build(name: 'Test') }

  before do
    allow(view).to receive(:resource_class) { Chouette::Network }
  end

  describe "form" do
    it "should render input for name" do
      render
      expect(rendered).to have_selector("form") do
        with_selector "input[type=text][name=?]", network.name
      end
    end
  end
end
