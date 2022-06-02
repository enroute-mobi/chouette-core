RSpec.describe Control::Context::OperatingPeriod::Run do
  let!(:organisation){create(:organisation)}
  let!(:user){create(:user, :organisation => organisation)}

  let!(:context) do
    Chouette.create do
      line :first
      line :second
      line :third

      stop_area :specific_stop

      workbench :workbench do
        shape :shape

        referential :referential, lines: [:first, :second, :third] do
          time_table :time_table

          route line: :first do
            journey_pattern shape: :shape do
              vehicle_journey :first, time_tables: [:time_table]
            end
          end
          route line: :second do
            journey_pattern  shape: :shape do
              vehicle_journey :second, time_tables: [:time_table]
            end
          end
        end
      end
    end
  end

  let!(:control_list) do
    Control::List.create! name: "Control List 1", workbench: context.workbench(:workbench)
  end

  let!(:control_context1) do
    Control::Context::OperatingPeriod.create!(
      name: "Control Context OperatingPeriod 1",
      control_list: control_list,
      next_days: 10
    )
  end

  let!(:control_context2) do
   Control::Context::OperatingPeriod.create!(
     name: "Control Context OperatingPeriod 2",
     control_list: control_list,
     next_days: 50
   )
  end

  let!(:control_dummy) do
    Control::Dummy.create(
      name: "Control dummy 1",
      control_context: control_context1,
      position: 0
    )
  end

  let(:control_list_run) do
    Control::List::Run.new(
      name: "Control List Run 1",
      referential: referential,
      workbench: workbench,
      original_control_list: control_list,
      creator: user
    )
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:referential) { context.referential(:referential) }
  let(:vehicle_journey_first) { context.vehicle_journey(:first) }
  let(:vehicle_journey_second) { context.vehicle_journey(:second) }
  let(:time_table) { context.time_table(:time_table) }

  subject { control_list_run.control_context_runs }

  describe ".context" do
    before do
      referential.switch

      control_list.reload
      control_list_run.build_with_original_control_list
      control_list_run.save
      control_list_run.reload
    end

    let(:control_context_run_first) { subject.find{ |e| e.name == "Control Context OperatingPeriod 1" } }
    let(:control_context_run_second) { subject.find{ |e| e.name == "Control Context OperatingPeriod 2" } }

    context "when Control is created with next days context" do
      let(:control_context_run_names) do
        subject.map{ |context_run| context_run.name}
      end

      let(:control_run_names) do
        subject.map{ |context_run| context_run.control_runs.map(&:name)}.flatten
      end

      it "should return all control_context_runs" do
        expect(control_context_run_names).to match_array([control_context1.name, control_context2.name])
      end

      it "should return all control_runs for each control_context_runs" do
        expect(control_run_names).to include(control_dummy.name)
      end
    end

    describe "#VehicleJourney" do
      context "when the value of next_days is into the date range" do
        let(:vehicle_journeys) { control_context_run_first.vehicle_journeys }

        it "should return all vehicle_journeys" do
          expect(vehicle_journeys).to match_array([ vehicle_journey_first, vehicle_journey_second ])
        end
      end

      context "when the value of next_days is not into the date range" do

        let(:vehicle_journeys) { control_context_run_second.vehicle_journeys }

        before { time_table.destroy }

        it "should return nil" do
          expect(vehicle_journeys).to be_empty
        end
      end
    end

    describe "#Line" do
      context "when the value of next_days is into the date range" do
        let(:lines) { control_context_run_first.lines }

        it "should return first and second" do
          expect(lines).to match_array([ context.line(:first), context.line(:second) ])
        end
      end
    end
  end
end