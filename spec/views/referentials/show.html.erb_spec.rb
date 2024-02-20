RSpec.describe "referentials/show" do
  subject { render template: "referentials/show" }

  let(:context) { Chouette.create { referential } }
  let(:referential) { context.referential }

  before do
    assign :referential, referential#.decorate

    # Required by #page_header_content_for :-/
    allow(view).to receive(:resource).and_return(referential)
    allow(view).to receive(:resource_class).and_return(referential.class)

    # Required by filters :-/
    controller.request.path_parameters[:id] = referential.id

    # View fails without @reflines :-/
    assign :reflines, []
  end

  describe "Workbench name" do
    it "displays Workbench name" do
      is_expected.to have_selector(".dl-term", text: referential.human_attribute_name(:workbench))
      is_expected.to have_selector(".dl-def", text: referential.workbench.name)
    end

    context "when no Workbench is associated" do
      before { referential.workbench = nil }

      it { is_expected.to_not have_selector(".dl-term", text: referential.human_attribute_name(:workbench)) }
    end
  end
end

# Legacy view specs
RSpec.describe "referentials/show", type: :view do
  let(:policy_context_class) { Policy::Context::Workbench }
  let(:referential) do
    referential = create(:workbench_referential, organisation: organisation, workbench: current_workbench)
    assign :referential, referential.decorate(context: {
      current_organisation: referential.organisation
    })
  end
  let(:permissions){ [] }
  let(:readonly){ false }

  before :each do
    allow(referential.object).to receive(:referential_read_only?){ readonly }

    assign :reflines, []
    allow(view).to receive(:resource).and_return(referential)
    allow(view).to receive(:resource_class).and_return(referential.class)
    allow(view).to receive(:has_feature?).and_return(true)
    controller.request.path_parameters[:id] = referential.id
    allow(view).to receive(:params).and_return(ActionController::Parameters.new(action: :show))

    render template: "referentials/show", layout: "layouts/application"
  end

  it "should not present edit button" do
    expect(rendered).to_not have_selector("a[href=\"#{view.edit_referential_path(referential)}\"]")
  end

  with_permission "referentials.update" do
    it "should present edit button" do
      expect(rendered).to have_selector("a[href=\"#{view.edit_referential_path(referential)}\"]")
    end

    context "with a readonly referential" do
      let(:readonly){ true }
      it "should not present edit button" do
        expect(rendered).to_not have_selector("a[href=\"#{view.edit_referential_path(referential)}\"]")
      end
    end
  end
end
