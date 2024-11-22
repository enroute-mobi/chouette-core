# frozen_string_literal: true

RSpec.describe Control::PresenceCode do
  it 'should be one of the available Control' do
    expect(Control.available).to include(described_class)
  end

  describe Control::PresenceCode::Run do
    it { should validate_presence_of :target_model }
    it { should validate_presence_of :target_code_space_id }
    it do
      should enumerize(:target_model).in(
        %w[
          Line
          LineGroup
          LineNotice
          Company
          StopArea
          StopAreaGroup
          Entrance
          Shape
          PointOfInterest
          ServiceFacilitySet
          AccessibilityAssessment
          Fare::Zone
          LineRoutingConstraintZone
          Document
          Contract
          Route
          JourneyPattern
          VehicleJourney
          TimeTable
        ]
      )
    end

    let(:control_list_run) do
      Control::List::Run.create referential: referential, workbench: context.workbench
    end

    let(:control_run) do
      Control::PresenceCode::Run.create(
        control_list_run: control_list_run,
        criticity: "warning",
        options: { target_model: target_model, target_code_space_id: target_code_space_id },
        position: 0
      )
    end

    let(:target_code_space_id) { context.code_space&.id }
    let(:referential) { nil }

    describe '#run' do
      subject { control_run.run }

      let(:expected_message) do
        an_object_having_attributes({
          source: source,
          criticity: "warning",
          message_attributes: {
            "name" => source.name,
            "code_space_name" => "test"
          }
        })
      end

      before { referential&.switch }

      describe "#StopArea" do
        let(:target_model) { "StopArea" }
        let(:source) { context.stop_area }

        context "when a StopArea exists without code" do
          let(:context) do
            Chouette.create do
              code_space short_name: "test"
              stop_area
            end
          end

          it "should create a warning message" do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end

        context "when StopArea exist with a code 'test'" do
          let(:context) do
            Chouette.create do
              code_space short_name: "test"
              stop_area codes: { test: 'dummy' }
            end
          end

          it "should have no warning message created" do
            subject

            expect(control_run.control_messages).to be_empty
          end
        end
      end

      describe "#Line" do
        let(:target_model) { "Line" }
        let(:source) { context.line }


        context "when a Line exists without code" do
          let(:context) do
            Chouette.create do
              code_space short_name: "test"
              line
            end
          end

          it "should create a warning message" do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end

        context "when a Line exists a code 'test'" do
          let(:context) do
            Chouette.create do
              code_space short_name: "test"
              line codes: { test: 'dummy' }
            end
          end

          it "should have no warning message created" do
            subject

            expect(control_run.control_messages).to be_empty
          end
        end
      end

      describe '#PointOfInterest' do
        let(:target_model) { 'PointOfInterest' }
        let(:source) { context.point_of_interest }


        context 'when a PointOfInterest exists without code' do
          let(:context) do
            Chouette.create do
              code_space short_name: 'test'
              point_of_interest
            end
          end

          it 'should create a warning message' do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end

        context 'when a PointOfInterest exists a code "test"' do
          let(:context) do
            Chouette.create do
              code_space short_name: 'test'
              point_of_interest codes: { test: 'dummy' }
            end
          end

          it 'should have no warning message created' do
            subject

            expect(control_run.control_messages).to be_empty
          end
        end
      end
    end
  end
end
