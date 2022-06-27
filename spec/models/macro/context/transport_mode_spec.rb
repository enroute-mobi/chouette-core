RSpec.describe Macro::Context::TransportMode::Run do
  let!(:organisation){create(:organisation)}
  let!(:user){create(:user, :organisation => organisation)}

  let!(:macro_list) do
    Macro::List.create! name: "Macro List 1", workbench: context.workbench
  end

  let!(:macro_context1) do
    Macro::Context::TransportMode.create! name: "Macro Context TransportMode 1", macro_list: macro_list, options: { transport_mode: "bus" }
  end

  let!(:macro_context2) do
   Macro::Context::TransportMode.create! name: "Macro Context TransportMode 2", macro_list: macro_list, options: { transport_mode: "tram" }
  end

  let!(:macro_dummy) do
    Macro::Dummy.create name: "Macro dummy 1", macro_context: macro_context1, position: 0
  end

  let(:macro_list_run) do
    Macro::List::Run.new name: "Macro List Run 1", referential: context.referential, workbench: context.workbench, original_macro_list: macro_list, creator: user
  end

  subject { macro_list_run.macro_context_runs }

  describe ".context" do

    let(:context) do
      Chouette.create do
        stop_area :first
        stop_area :second

        referential do
          route :route, stop_areas: [:first, :second] do
            journey_pattern :journey_pattern
          end
        end
      end
    end

    let(:route) { context.route(:route) }
    let(:line) { route.line }
    let(:first_stop_point) { route.stop_points.first }
    let(:second_stop_point) { route.stop_points.second }
    let(:first_stop_area) { context.stop_area(:first) }
    let(:second_stop_area) { context.stop_area(:second) }
    let(:journey_pattern) { context.journey_pattern(:journey_pattern) }
    let(:vehicle_journey) { journey_pattern.reload.vehicle_journeys.find_by_objectid('objectid-vehicle-journey-in-context') }

    before { context.referential.switch }

    context "when macro is created with transport mode context" do
      let(:macro_context_run_names) do
        subject.map{ |context_run| context_run.name}
      end

      let(:macro_run_names) do
        subject.map{ |context_run| context_run.macro_runs.map(&:name)}.flatten
      end

      before do
        journey_pattern.vehicle_journeys.create(
          objectid: 'objectid-vehicle-journey-in-context',
          route: route, transport_mode: 'bus'
        )
        macro_list.reload
        macro_list_run.build_with_original_macro_list
        macro_list_run.save
        macro_list_run.reload
      end

      it "should return all macro_context_runs" do
        expect(macro_context_run_names).to match_array([macro_context1.name, macro_context2.name])
      end

      it "should return all macro_runs for each macro_context_runs" do
        expect(macro_run_names).to include(macro_dummy.name)
      end

      describe "#scope" do
        subject do
          macro_list_run.macro_context_runs.map{ |context_run| context_run.scope.send collection }.flatten.compact
        end

        describe "#lines" do
          let(:collection) { :lines }

          it { is_expected.to include an_object_having_attributes(id: line.id) }
        end

        describe "#routes" do
          let(:collection) { :routes }

          it { is_expected.to include an_object_having_attributes(id: route.id) }
        end

        describe "#stop_points" do
          let(:collection) { :stop_points }

          it { is_expected.to include an_object_having_attributes(id: first_stop_point.id) }
          it { is_expected.to include an_object_having_attributes(id: second_stop_point.id) }
        end

        describe "#stop_areas" do
          let(:collection) { :stop_areas }

          it { is_expected.to include an_object_having_attributes(id: first_stop_area.id) }
          it { is_expected.to include an_object_having_attributes(id: second_stop_area.id) }
        end

        describe "#journey_patterns" do
          let(:collection) { :journey_patterns }

          it do
            is_expected.to include an_object_having_attributes(id: journey_pattern.id)
          end
        end

        describe "#vehicle_journeys" do
          let(:collection) { :vehicle_journeys }

          it do
            is_expected.to include an_object_having_attributes(id: vehicle_journey.id)
          end
        end
      end
    end
  end
end