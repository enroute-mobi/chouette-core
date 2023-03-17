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

RSpec.describe "workbenches/show", :type => :view do
  let(:context) do
    Chouette.create do
      workgroup do
        workbench(:user_workbench) { referential :user_referential }
        workbench { referential :other_referential }
      end
    end
  end

  let!(:workbench) { assign :workbench, context.workbench(:user_workbench) }
  let!(:same_organisation_referential) { context.referential(:user_referential) }
  let!(:different_organisation_referential) { context.referential(:other_referential) }
  let!(:referentials) { assign :wbench_refs, paginate_collection(workbench.all_referentials, ReferentialDecorator) }
  let!(:search) {assign :search, Search::Workbench.new(referentials, {}, workbench: workbench) }

  before :each do
    allow(view).to receive(:resource_class).and_return(Workbench)
    controller.request.path_parameters[:id] = workbench.id

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
