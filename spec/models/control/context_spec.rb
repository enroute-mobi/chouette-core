RSpec.describe Control::Context do
  let(:control_list) do
    Control::List.create name: "Control List 1", workbench: context.workbench
  end

  let(:control_context) do
    Control::Context.create name: "Control Context 1", control_list: control_list
  end

  let(:control_context_run) do
    Control::Context::Run.create name: "Control Context Run 1", control_list_run: control_list_run, options: {transport_mode: "bus"}, type: "Control::Context::Run"
  end

  let(:control_run) { Control::Base::Run.new control_list_run: control_list_run, control_context_run: control_context_run}

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

    describe "#control_run is created with referential" do
      let(:control_list_run) do
        Control::List::Run.create(
          name: "Control List Run 1",
          referential: context.referential,
          workbench: context.workbench,
          original_control_list: control_list
        )
      end

      context "when model is stop_areas" do
        let(:model) { control_run.context.context.stop_areas }
        let(:referential_stop_area_ids) { context.referential.stop_areas.pluck(:id) }

        it {is_expected.to match_array(referential_stop_area_ids)}
      end

      context "when model is lines" do
        let(:model) { control_run.context.context.lines }
        let(:referential_line_ids) { context.referential.lines.pluck(:id) }

        it {is_expected.to match_array(referential_line_ids)}
      end

      context "when model is routes" do
        let(:model) { control_run.context.context.routes }
        let(:referential_route_ids) { context.referential.routes.pluck(:id) }

        it {is_expected.to match_array(referential_route_ids)}
      end

      context "when model is stop_points" do
        let(:model) { control_run.context.context.stop_points }
        let(:referential_stop_point_ids) { context.referential.stop_points.pluck(:id) }

        it {is_expected.to match_array(referential_stop_point_ids)}
      end

      context "when model is journey_patterns" do
        let(:model) { control_run.context.context.journey_patterns }
        let(:referential_journey_pattern_ids) { context.referential.journey_patterns.pluck(:id) }

        it {is_expected.to match_array(referential_journey_pattern_ids)}
      end

      context "when model is vehicle_journeys" do
        let(:model) { control_run.context.context.vehicle_journeys }
        let(:referential_vehicle_journey_ids) { context.referential.vehicle_journeys.pluck(:id) }

        it {is_expected.to match_array(referential_vehicle_journey_ids)}
      end
    end

    describe "#control_run is created without referential" do
      let(:control_list_run) do
        Control::List::Run.create name: "Control List Run 1", workbench: context.workbench, original_control_list: control_list
      end

      context "when model is stop_areas" do
        let(:model) { control_run.context.context.stop_areas }
        let(:workbench_stop_area_ids) { context.workbench.stop_areas.pluck(:id) }

        it {is_expected.to match_array(workbench_stop_area_ids)}
      end

      context "when model is lines" do
        let(:model) { control_run.context.context.lines }
        let(:workbench_line_ids) { context.workbench.lines.pluck(:id) }

        it {is_expected.to match_array(workbench_line_ids)}
      end

      context "when model is routes" do
        let(:model) { control_run.context.context.routes }

        it {is_expected.to match_array([])}
      end

      context "when model is stop_points" do
        let(:model) { control_run.context.context.stop_points }

        it {is_expected.to match_array([])}
      end

      context "when model is journey_patterns" do
        let(:model) { control_run.context.context.journey_patterns }

        it {is_expected.to match_array([])}
      end

      context "when model is vehicle_journeys" do
        let(:model) { control_run.context.context.vehicle_journeys }

        it {is_expected.to match_array([])}
      end
    end
  end
end
