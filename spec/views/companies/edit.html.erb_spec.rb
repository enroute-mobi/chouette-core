describe "/companies/edit", :type => :view do

  let(:context) do
    Chouette.create { company }
  end

  let!(:workbench) { assign :workbench, context.workbench }
  let!(:company) { assign :company, context.company }

  before do
    allow(view).to receive(:resource) { company }
    allow(view).to receive(:resource_class) { Chouette::Company }
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
