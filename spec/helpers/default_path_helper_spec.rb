RSpec.describe DefaultPathHelper do
  let(:context) do
    Chouette.create { workbench }
  end

  let(:workbench) { context.workbench }

  before do
    allow(helper).to receive(:current_organisation).and_return(workbench.organisation)
  end

  describe "#default_shapes_path" do
    subject { helper.default_shapes_path(shape_referential) }
    let(:shape_referential) { workbench.shape_referential }

    context "when the ShapeReferential default workbench is 42" do
      before { workbench.update id: 42 }
      it { is_expected.to eq("/workbenches/42/shape_referential/shapes") }
    end
  end
end
