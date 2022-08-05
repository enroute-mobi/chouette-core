describe "/companies/new", type: :view do

  let(:context) { Chouette.create { company } }

  let!(:workbench) { assign :workbench, context.workbench }
  let!(:line_referential) { assign :line_referential, context.line_referential }
  let!(:company) { assign :company, context.company }

  before do
    allow(view).to receive(:resource) { company }
    allow(view).to receive(:resource_class) { Chouette::Company }
  end

  describe "form" do
    it "should render input for name" do
      render
      expect(rendered).to have_selector("form") do
        with_selector "input[type=text][name=?]", company.name
      end
    end
  end
end
