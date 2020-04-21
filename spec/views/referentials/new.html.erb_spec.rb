
describe "referentials/new", :type => :view do

  let!(:workbench) { assign(:workbench, create(:workbench)) }
  let!(:referential) { assign(:referential, build(:referential, :workbench => workbench)) }

  before(:each) do
    allow(view).to receive(:has_feature?).and_return(true)
  end

  it "should have a textfield for name" do
    render
    expect(rendered).to have_field("referential[name]")
  end

  it "should present use current offer switch" do
    render
    expect(rendered).to have_css("input#referentialfrom_current_offer")
  end

  context "from a already existing referential (duplication)" do
    before do
      referential.created_from = create(:referential)
    end

    it "should not present use current offer switch" do
      expect(rendered).to_not have_css("input#referentialfrom_current_offer")
    end
  end
end
