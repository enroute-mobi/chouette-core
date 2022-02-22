RSpec.describe Macro::CreateShape do
  it "should be one of the available Macro" do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::CreateShape::Run do
    let(:macro_list_run) do
      Macro::List::Run.new referential: context.referential, workbench: context.workbench
    end
    subject(:macro_run) { Macro::CreateShape::Run.new macro_list_run: macro_list_run }

    describe ".run" do
      subject { macro_run.run }

      let(:context) do
        Chouette.create do

          stop_area :first, name: "first", latitude: 43.574325, longitude: 7.091888
          stop_area :middle, name: "middle", latitude: 43.575067, longitude: 7.095608
          stop_area :last, name: "last", latitude: 43.574477, longitude: 7.099041

          referential do
            route stop_areas: [:first, :middle, :last] do
              journey_pattern id: 1, shape: nil
            end
          end
        end
      end

      let(:journey_pattern) { context.journey_pattern }
      let(:workgroup) { context.workgroup }

      before do
        context.referential.switch
        workgroup.owner.update features: ["route_planner"]
      end

      context "when the JourneyPattern has no Shape" do
        let(:shape) { Shape.first }
        let(:geom) { journey_pattern.reload.shape&.geometry.to_s }

        it "should create shape" do
          expect { subject }.to change { Shape.count }.from(0).to(1)
        end

        it "should update association between Journey Pattern and Shape" do
          subject

          expect change { journey_pattern.reload.shape }.from(nil).to(shape)
        end
      end
    end
  end
end
