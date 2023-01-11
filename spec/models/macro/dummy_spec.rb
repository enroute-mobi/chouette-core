RSpec.describe Macro::Dummy do

  describe Macro::Dummy::Run do

    let(:macro_list_run) do
      Macro::List::Run.create referential: context.referential, workbench: context.workbench
    end

    let(:macro_run) do
      Macro::Dummy::Run.create(
        macro_list_run: macro_list_run,
        position: 0,
        options: {
          expected_result: "error",
          target_model: target_model
        }
      )
    end

    let(:context) do
      Chouette.create do
        stop_area
        referential
      end
    end

    let(:referential) { context.referential }

    subject { macro_run.run }

    let(:expected_message) do
      an_object_having_attributes({
        criticity: macro_run.expected_result,
        message_attributes: {
          "name" => source.name,
          "result" => "error"
        },
        source: source,
      })
    end

    before { referential.switch }

    describe "#run" do
      let(:target_model) { "StopArea" }
      let(:source) { context.stop_area }

      it "should create an error message" do
        subject
        expect(macro_run.macro_messages).to include(expected_message)
      end
    end
  end
end
