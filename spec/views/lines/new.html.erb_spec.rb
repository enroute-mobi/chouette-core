describe "/lines/new", :type => :view do
  let(:context) { Chouette.create { line } }

  let!(:workbench) { assign :workbench, context.workbench }
  let!(:line_referential) { assign :line_referential, context.line_referential }
  let!(:line) { assign :line, context.line }

  describe "form" do
    before :each do
      allow(template).to receive(:candidate_line_providers).and_return([line.line_provider])
      allow(view).to receive(:resource).and_return(line)
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
