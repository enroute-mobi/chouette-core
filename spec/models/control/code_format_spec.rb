RSpec.describe Control::CodeFormat do

  describe Control::CodeFormat::Run do

    let(:control_list_run) do
      Control::List::Run.create referential: context.referential, workbench: context.workbench
    end

    let(:control_run) do
      Control::CodeFormat::Run.create(
        control_list_run: control_list_run,
        criticity: "warning",
        options: {
          target_model: target_model,
          target_code_space_id: target_code_space_id,
          expected_format: '[BFHJ][0-9]{4,6}-[A-Z]{3}'
        },
        position: 0
      )
    end

    let(:target_code_space_id) { context.code_space.id }
    let(:referential) { context.referential }

    subject { control_run.run }

    let(:expected_message) do
      an_object_having_attributes({
        source: source,
        criticity: "warning",
        message_attributes: {
          'name' => source.try(:name) || source.id,
          'code_space_name' => 'test',
          'expected_format' => '[BFHJ][0-9]{4,6}-[A-Z]{3}'
        },
        message_key: 'code_format'
      })
    end

    describe "#StopArea" do
      let(:context) do
        Chouette.create do
          code_space short_name: 'test'
          stop_area :with_a_good_code, codes: { test: 'B9999-AAA' }
          stop_area :with_a_bad_code, codes: { test: 'BAD_CODE' }
          referential
        end
      end

      before { referential.switch }
      let(:target_model) { "StopArea" }
      let(:source) { context.stop_area(:with_a_bad_code) }
      let(:stop_area_with_a_good_code) { context.stop_area(:with_a_good_code) }

      let(:message_for_good_code) { control_run.control_messages.find{ |msg| msg.source == stop_area_with_a_good_code } }

      context "when a StopArea exists a space code 'test'" do
        it "should create a warning message for the StopArea with a bad code" do
          subject

          expect(control_run.control_messages).to include(expected_message)
        end

        it "should not create a warning message for the StopArea with a goof code" do
          subject

          expect(message_for_good_code).to be_nil
        end
      end
    end

    describe "#VehicleJourney" do
      let(:context) do
        Chouette.create do
          code_space short_name: 'test'
          referential do
            vehicle_journey :with_a_good_code
            vehicle_journey :with_a_bad_code
          end
        end
      end

      let(:target_model) { "VehicleJourney" }
      let(:source) { context.vehicle_journey(:with_a_bad_code) }
      let(:vehicle_journey_with_a_good_code) { context.vehicle_journey(:with_a_good_code) }
      let(:vehicle_journey_with_a_bad_code) { context.vehicle_journey(:with_a_bad_code) }
      let(:message_for_good_code) { control_run.control_messages.find{ |msg| msg.source == vehicle_journey_with_a_good_code } }

      before do
        referential.switch
        vehicle_journey_with_a_good_code.codes.create(value: 'B9999-AAA', code_space: context.code_space)
        vehicle_journey_with_a_bad_code.codes.create(value: 'BAD_CODE', code_space: context.code_space)
      end

      context "when a VehicleJourney exists a space code 'test'" do
        it "should create a warning message for the VehicleJourney with a bad code" do
          subject

          expect(control_run.control_messages).to include(expected_message)
        end

        it "should not create a warning message for the VehicleJourney with a goof code" do
          subject

          expect(message_for_good_code).to be_nil
        end
      end
    end

  end
end