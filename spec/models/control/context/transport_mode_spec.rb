RSpec.describe Control::Context::TransportMode::Run do
  let!(:organisation){create(:organisation)}
  let!(:user){create(:user, :organisation => organisation)}

  let!(:context) do
    Chouette.create do

      company :company

      line :first, transport_mode: 'bus', company: :company
      line :second, transport_mode: 'bus', company: :company
      line :third, transport_mode: 'bus', company: :company

      workbench :workbench do
        referential :referential, lines: [:first, :second, :third] do
          route line: :first do
            journey_pattern do
              vehicle_journey :first
            end
          end
          route line: :second do
            journey_pattern do
              vehicle_journey :second
            end
          end
        end
      end
    end
  end

  let!(:control_list) do
    Control::List.create! name: "Control List", workbench: workbench
  end

  let!(:control_context) do
    Control::Context::TransportMode.create!(
      name: "Control Context TransportMode",
      control_list: control_list,
      transport_mode: 'bus'
    )
  end

  let!(:control_dummy) do
    Control::Dummy.create(
      name: "Control dummy",
      control_context: control_context,
      position: 0
    )
  end

  let(:control_list_run) do
    Control::List::Run.new(
      name: "Control List Run",
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
  let(:first_line) { context.line(:first) }
  let(:second_line) { context.line(:second) }
  let(:third_line) { context.line(:third) }
  let(:company) { context.company(:company) }

  let(:control_context_runs) { control_list_run.control_context_runs }

  describe ".context" do
    before do
      referential.switch

      control_list.reload
      control_list_run.build_with_original_control_list
      control_list_run.save
      control_list_run.reload
    end

    let(:control_context_run) { control_context_runs.find{ |e| e.name == "Control Context TransportMode" } }


    describe "#lines" do
      let(:lines) { control_context_run.lines }

      it { expect(lines).to match_array([first_line, second_line, third_line]) }
    end

    describe "#companies" do
      let(:companies) { control_context_run.companies }

      it { expect(companies).to match_array([company]) }
    end
  end
end