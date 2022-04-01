RSpec.describe Macro::Dummy do

  describe Macro::Dummy::Run do

    let(:macro_list_run) do
      Macro::List::Run.create referential: context.referential, workbench: context.workbench
    end

    let(:macro_run) do
      Macro::Dummy::Run.create(
        macro_list_run: macro_list_run,
        target_model: target_model,
        position: 0
      )
    end

    let(:referential) { context.referential }

    subject { macro_run.run }

    let(:expected_message) do
      an_object_having_attributes({
        source: source,
        criticity: "info",
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

        expect(macro_run.macro_messages).to include(expected_message)
      end
    end
  end
end