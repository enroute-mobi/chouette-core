describe "referentials/new", :type => :view do
  let(:context) do
    Chouette.create { workbench }
  end

  let!(:workbench) { assign :workbench, context.workbench }
  let!(:referential) { assign :referential, workbench.referentials.build }

  before(:each) do
    allow(view).to receive(:has_feature?).and_return(true)
    allow(view).to receive(:resource).and_return(referential)
  end

  it "should have a textfield for name" do
    render
    expect(rendered).to have_field("referential[name]")
  end

  it "should present use current offer switch" do
    render
    expect(rendered).to have_css("input#referential_from_current_offer")
  end

  context "from a already existing referential (duplication)" do

    let(:context) do
      Chouette.create { workbench { referential(:existing) } }
    end

    before do
      referential.created_from = context.referential(:existing)
    end

    it "should not present use current offer switch" do
      expect(rendered).to_not have_css("input#referential_from_current_offer")
    end
  end
end
