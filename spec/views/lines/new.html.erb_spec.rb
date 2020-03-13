
describe "/lines/new", :type => :view do

  let!(:network) { create(:network) }
  let!(:company) { create(:company) }
  let!(:line) { assign(:line, build(:line, :network => network, :company => company, line_referential: line_referential )) }
  let!(:line_referential) { assign :line_referential, create(:line_referential, workgroup: create(:workgroup)) }

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
