RSpec.describe Control::PresenceCode do

  describe Control::PresenceCode::Run do

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
    subject { control_run.run }

    let(:expected_message) do
      an_object_having_attributes({
        source: source,
        criticity: "warning",
        message_attributes: {"name" => source.name}
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

    describe "#Line" do
      let(:target_model) { "Line" }
      let(:source) { referential.lines.first }


      context "when a Line exists without code" do
        let(:context) do
          Chouette.create do
            code_space short_name: "test"
            line
            referential
          end
        end

        before { referential.switch }

        it "should create a warning message" do
          subject

          expect(control_run.control_messages).to include(expected_message)
        end
      end

      context "when a Line exists a code 'test'" do
        let(:context) do
          Chouette.create do
            code_space short_name: 'test'
            line codes: { test: 'dummy'} #FIXME: can not find workgroup in factory
            referential
          end
        end

        before { referential.switch }

        xit "should have no warning message created" do
          subject

          expect(control_run.control_messages).to be_empty
        end
      end
    end

  end
end