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
        %w[Line StopArea VehicleJourney]
      )
    end

    let(:control_list_run) do
      Control::List::Run.create referential: context.referential, workbench: context.workbench
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
    let(:referential) { context.referential }

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

      before { referential.switch }

      describe "#StopArea" do
        let(:target_model) { "StopArea" }
        let(:source) { context.route.stop_areas.first }

        context "when a StopArea exists without code" do
          let(:context) do
            Chouette.create do
              code_space short_name: "test"
              referential do
                route
              end
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
              stop_area :departure, codes: { test: 'dummy'}
              stop_area :arrival, codes: { test: 'dummy'}
              referential do
                route stop_areas: [:departure, :arrival]
              end
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
        let(:source) { referential.lines.first }


        context "when a Line exists without code" do
          let(:context) do
            Chouette.create do
              code_space short_name: "test"
              referential
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
              referential
            end
          end

          before { context.referential.lines.first.codes.create(code_space: context.code_space, value: 'dummy') }

          it "should have no warning message created" do
            subject

            expect(control_run.control_messages).to be_empty
          end
        end
      end
    end
  end
end
