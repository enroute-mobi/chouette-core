RSpec.describe Macro::Context do
  let(:macro_list) do
    Macro::List.create name: "Macro List 1", workbench: context.workbench
  end

  let(:macro_context) do
    Macro::Context.create name: "Macro Context 1", macro_list: macro_list
  end

  let(:macro_context_run) do
    Macro::Context::Run.create name: "Macro Context Run 1", macro_list_run: macro_list_run, options: {transport_mode: "bus"}, type: "Macro::Context::Run"
  end

  let(:macro_run) { Macro::Base::Run.new macro_list_run: macro_list_run, macro_context_run: macro_context_run}

  subject { model.pluck(:id) }

  describe ".context" do
    let(:context) do
      Chouette.create do
        referential do
          journey_pattern
        end
      end
    end

    before { context.referential.switch }

    describe "#macro_run is created with referential" do
      let(:macro_list_run) do
        Macro::List::Run.create(
          name: "Macro List Run 1",
          referential: context.referential,
          workbench: context.workbench,
          original_macro_list: macro_list
        )
      end

      context "when model is stop_areas" do
        let(:model) { macro_run.context.context.stop_areas }
        let(:referential_stop_area_ids) { context.referential.stop_areas.pluck(:id) }

        it {is_expected.to match_array(referential_stop_area_ids)}
      end

      context "when model is lines" do
        let(:model) { macro_run.context.context.lines }
        let(:referential_line_ids) { context.referential.lines.pluck(:id) }

        it {is_expected.to match_array(referential_line_ids)}
      end

      context "when model is routes" do
        let(:model) { macro_run.context.context.routes }
        let(:referential_route_ids) { context.referential.routes.pluck(:id) }

        it {is_expected.to match_array(referential_route_ids)}
      end

      context "when model is stop_points" do
        let(:model) { macro_run.context.context.stop_points }
        let(:referential_stop_point_ids) { context.referential.stop_points.pluck(:id) }

        it {is_expected.to match_array(referential_stop_point_ids)}
      end

      context "when model is journey_patterns" do
        let(:model) { macro_run.context.context.journey_patterns }
        let(:referential_journey_pattern_ids) { context.referential.journey_patterns.pluck(:id) }

        it {is_expected.to match_array(referential_journey_pattern_ids)}
      end

      context "when model is vehicle_journeys" do
        let(:model) { macro_run.context.context.vehicle_journeys }
        let(:referential_vehicle_journey_ids) { context.referential.vehicle_journeys.pluck(:id) }

        it {is_expected.to match_array(referential_vehicle_journey_ids)}
      end
    end

    describe "#macro_run is created without referential" do
      let(:macro_list_run) do
        Macro::List::Run.create name: "Macro List Run 1", workbench: context.workbench, original_macro_list: macro_list
      end

      context "when model is stop_areas" do
        let(:model) { macro_run.context.context.stop_areas }
        let(:workbench_stop_area_ids) { context.workbench.stop_areas.pluck(:id) }

        it {is_expected.to match_array(workbench_stop_area_ids)}
      end

      context "when model is lines" do
        let(:model) { macro_run.context.context.lines }
        let(:workbench_line_ids) { context.workbench.lines.pluck(:id) }

        it {is_expected.to match_array(workbench_line_ids)}
      end

      context "when model is routes" do
        let(:model) { macro_run.context.context.routes }

        it {is_expected.to match_array([])}
      end

      context "when model is stop_points" do
        let(:model) { macro_run.context.context.stop_points }

        it {is_expected.to match_array([])}
      end

      context "when model is journey_patterns" do
        let(:model) { macro_run.context.context.journey_patterns }

        it {is_expected.to match_array([])}
      end

      context "when model is vehicle_journeys" do
        let(:model) { macro_run.context.context.vehicle_journeys }

        it {is_expected.to match_array([])}
      end
    end
  end
end
