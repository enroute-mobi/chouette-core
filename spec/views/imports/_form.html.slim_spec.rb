RSpec.describe '/imports/_form', type: :view do
  let(:policy_context_class) { Policy::Context::Workbench }
  let(:import){ create :workbench_import, workbench: current_workbench }

  before do
    # assign :import, import
    # assign :workbench, workbench
    allow(view).to receive(:import).and_return(import)
    allow(view).to receive(:workbench).and_return(current_workbench)
    allow(view).to receive(:resource).and_return(import)
  end

  describe "option flag_urgent" do
    context "when the policy allows it" do
      let(:permissions) { ['referentials.flag_urgent'] }

      it "is visible" do
        render
        expect(rendered).to have_field('import[flag_urgent]')
      end
    end

    context "when the policy forbids it" do
      it "is hidden" do
        render
        expect(rendered).to_not have_field('import[flag_urgent]')
      end
    end
  end
end
