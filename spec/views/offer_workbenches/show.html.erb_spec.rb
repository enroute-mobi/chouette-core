require 'spec_helper'

RSpec::Matchers.define :have_box_for_item do |item, disabled|
  match do |actual|
    klass = "#{TableBuilderHelper.item_row_class_name([item])}-#{item.id}"
    if disabled
      selector = "tr.#{klass} [type=checkbox][disabled][value='#{item.id}']"
    else
      selector = "tr.#{klass} [type=checkbox][value='#{item.id}']:not([disabled])"
    end
    expect(actual).to have_selector(selector, count: 1)
  end
  description { "have a #{disabled ? "disabled ": ""}box for the item ##{item.id}" }
end


describe "workbenches/show", :type => :view do
  before(:each) do
    allow(view).to receive(:resource_class).and_return(Workbench)
  end
  
  let!(:ids) { ['STIF:CODIFLIGNE:Line:C00840', 'STIF:CODIFLIGNE:Line:C00086'] }
  let!(:lines) {
    ids.map do |id|
      create :line, objectid: id, line_referential: workbench.line_referential, referential: same_organisation_referential
    end
  }
  let!(:workbench){ assign :workbench, create(:workbench) }
  let!(:same_organisation_referential){ create :workbench_referential, workbench: workbench }
  let!(:different_organisation_referential) do
    create(
      :workbench_referential,
      workbench: create(:workbench, workgroup: workbench.workgroup),
      metadatas: [create(:referential_metadata, lines: lines)]
    )
  end
  let!(:referentials){
    same_organisation_referential && different_organisation_referential
    assign :wbench_refs, paginate_collection(Referential, ReferentialDecorator)
  }
  let!(:q) { assign :q_for_form, Ransack::Search.new(Referential) }
  before :each do
    same_organisation_referential.update metadatas: [create(:referential_metadata, lines: lines)]
    lines
    controller.request.path_parameters[:id] = workbench.id
    expect(workbench.referentials).to     include same_organisation_referential
    expect(workbench.referentials).to_not include different_organisation_referential
    expect(workbench.all_referentials).to include same_organisation_referential
    expect(workbench.all_referentials).to include different_organisation_referential
    render
  end

  it { should have_link_for_each_item(referentials, "show", -> (referential){ view.referential_path(referential) }) }

  context "without permission" do
    it "should disable all the checkboxes" do
      expect(rendered).to have_box_for_item same_organisation_referential, true
      expect(rendered).to have_box_for_item different_organisation_referential, true
    end
  end

  with_permission "referentials.destroy" do
    it "should enable the checkbox for the referential which belongs to the same organisation and disable the other one" do
      expect(rendered).to have_box_for_item same_organisation_referential, false
      expect(rendered).to have_box_for_item different_organisation_referential, true
    end
  end
end
