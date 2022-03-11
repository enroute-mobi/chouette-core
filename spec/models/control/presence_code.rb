RSpec.describe Control::PresenceCode do

  describe Control::PresenceCode::Run do

    let(:control_list_run) do
      Control::List::Run.create referential: context.referential, workbench: context.workbench
    end

    let(:control_run) do
      Control::PresenceCode::Run.create(
        control_list_run: control_list_run,
        criticity: "warning",
        options: { target_model: target_model, target_code_space: target_code_space },
        position: 0
      )
    end

    let(:target_code_space) { "test" }
    let(:referential) { context.referential }
    subject { control_run.run }

    let(:expected_message) do
      an_object_having_attributes({
        source: source,
        criticity: "warning",
        message_attributes: {"target_code_space" => target_code_space}
      })
    end

    before { referential.switch }

    describe "#StopArea" do
      let(:target_model) { "StopArea" }
      let(:source) { context.stop_area }

      context "when a StopArea exists without code" do
        let(:context) do
          Chouette.create do
            code_space short_name: "test"
            stop_area
            referential
          end
        end

        it "should create a warning message" do
          subject

          expect(control_run.control_messages).to include(expected_message)
        end
      end

      context "when a StopArea exists a code 'test'" do
        let(:context) do
          Chouette.create do
            code_space short_name: 'test'
            stop_area codes: { test: 'dummy'}
            referential
          end
        end
        before { referential.switch }

        it "should have no warning message created" do
          subject

          expect(control_run.control_messages).to be_empty
        end
      end
    end

  end
end