RSpec.describe '/imports/_form', type: :view do
  include Pundit::PunditViewPolicy

  let(:workbench){ create :workbench }
  let(:import){ create :workbench_import, workbench: workbench }

  before do
    # assign :import, import
    # assign :workbench, workbench
    allow(view).to receive(:import).and_return(import)
    allow(view).to receive(:workbench).and_return(workbench)
  end

  describe "option flag_urgent" do
    context "when the policy allows it" do
      before do
        allow_any_instance_of(ImportPolicy).to receive(:option_flag_urgent?).and_return(true)
      end
      it "is visible" do
        render
        expect(rendered).to have_field('import[flag_urgent]')
      end
    end

    context "when the policy forbids it" do
      before do
        allow_any_instance_of(ImportPolicy).to receive(:option_flag_urgent?).and_return(false)
      end
      it "is hidden" do
        render
        expect(rendered).to_not have_field('import[flag_urgent]')
      end
    end
  end
end
