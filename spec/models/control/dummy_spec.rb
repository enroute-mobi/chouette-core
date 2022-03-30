RSpec.describe Control::Dummy do

  describe Control::Dummy::Run do

    let(:control_list_run) do
      Control::List::Run.create referential: context.referential, workbench: context.workbench
    end

    let(:control_run) do
      Control::Dummy::Run.create(
        control_list_run: control_list_run,
        criticity: "warning",
        options: { target_model: target_model },
        position: 0
      )
    end

    let(:referential) { context.referential }

    subject { control_run.run }

    let(:expected_message) do
      an_object_having_attributes({
        source: source,
        criticity: "warning",
        message_attributes: { "id" => source.id, "name" => source.name }
      })
    end

    before { referential.switch }

    describe "#run" do
      let(:target_model) { "StopArea" }
      let(:source) { context.stop_area }
      let(:context) do
        Chouette.create do
          stop_area
          referential
        end
      end

      it "should create a warning message" do
        subject

        expect(control_run.control_messages).to include(expected_message)
      end
    end
  end
end