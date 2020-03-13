
describe "/lines/edit", :type => :view do

  let!(:network) { create(:network) }
  let!(:company) { create(:company) }
  let!(:line) { assign(:line, create(:line, :network => network, :company => company, :line_referential => line_referential)) }
  let!(:lines) { Array.new(2) { create(:line, :network => network, :company => company) } }
  let!(:line_referential) { assign :line_referential, create(:line_referential, workgroup: create(:workgroup)) }

  before :each do
    allow(view).to receive(:resource_class).and_return(Chouette::Line)
    allow(view).to receive(:referential).and_return(line_referential)
  end

  describe "form" do
    it "should render input for name" do
      render
      expect(rendered).to have_selector("form") do
        with_tag "input[type=text][name='line[name]'][value=?]", line.name
      end
    end

    it "should render a checkbox for each line" do
      render
      lines.each do |line|
        expect(rendered).to have_selector("form") do
          with_tag "input[type='checkbox'][value=?]", line.id.to_s
        end
      end

    end
  end
end
