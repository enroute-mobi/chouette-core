describe "/lines/new", :type => :view do

  let(:context) { Chouette.create { line_provider } }

  let!(:workbench) { assign :workbench, context.workbench }
  let!(:line_referential) { assign :line_referential, context.line_referential }
  let!(:line) { assign :line, context.line_provider.lines.build(name: 'Test') }

  describe "form" do
    before :each do
      allow(view).to receive(:resource_class).and_return(Chouette::Line)
      allow(view).to receive(:referential).and_return(line_referential)
    end

    it "should render input for name" do
      render
      expect(rendered).to have_selector("form") do
        with_selector "input[type=text][name=?]", line.name
      end
    end
  end
end
