require 'spec_helper'

describe "referentials/show", type: :view do

  let!(:referential) do
    referential = create(:workbench_referential)
    assign :referential, referential.decorate(context: {
      current_organisation: referential.organisation
    })
  end
  let(:organisation){ referential.try(:organisation) }
  let(:permissions){ [] }
  let(:current_organisation) { organisation }
  let(:readonly){ false }

  before :each do
    assign :reflines, []
    allow(view).to receive(:current_organisation).and_return(current_organisation)
    allow(view).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:resource).and_return(referential)
    allow(view).to receive(:has_feature?).and_return(true)
    allow(view).to receive(:user_signed_in?).and_return true
    allow(view).to receive(:mutual_workbench).and_return referential.workbench
    controller.request.path_parameters[:id] = referential.id
    allow(view).to receive(:params).and_return({action: :show})

    allow(referential).to receive(:referential_read_only?){ readonly }
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
