describe "/companies/edit", :type => :view do

  let(:context) do
    Chouette.create { company }
  end

  let!(:workbench) { assign :workbench, context.workbench }
  let!(:company) { assign :company, context.company }
  let(:line_provider) { build :line_provider, line_referential: line_referential, workbench: workbench }
  let!(:line_referential) { assign :line_referential, create(:line_referential, workgroup: workbench.workgroup) }

  before do
    allow(view).to receive(:resource) { company }
    allow(view).to receive(:resource_class) { Chouette::Company }
    allow(template).to receive(:candidate_line_providers).and_return([line_provider])
  end

  describe "form" do
    it "should render input for name" do
      render
      expect(rendered).to have_selector("form") do
        with_tag "input[type=text][name='company[name]'][value=?]", company.name
      end
    end
  end
end
