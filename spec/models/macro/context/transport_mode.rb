RSpec.describe Macro::Context::TransportMode::Run do
  let(:macro_list) do
    Macro::List.create name: "Macro List 1", workbench: context.workbench
  end
  let(:macro_list_run) do
    Macro::List::Run.create name: "Macro List Run 1", referential: context.referential, workbench: context.workbench, original_macro_list: macro_list
  end
  let(:macro_context) do
    Macro::Context::TransportMode.create name: "Macro Context TransportMode 1", macro_list: macro_list
  end
  let(:macro_context_run) do
    Macro::Context::TransportMode::Run.create name: "Macro Context TransportMode Run 1", macro_list_run: macro_list_run, macro_context: macro_context, options: {transport_mode: "bus"}
  end
  let(:macro_run) { Macro::Base::Run.new macro_list_run: macro_list_run, macro_context_run: macro_context_run}

  subject { macro_run.context.class }

  describe ".context" do

    let(:context) do
      Chouette.create do
        referential do
          journey_pattern
        end
      end
    end

    before { context.referential.switch }

    context "when macro_run is created with transport mode context" do
      it "should return Macro::Context::TransportMode::Run in the context method" do
        is_expected.to eq(Macro::Context::TransportMode::Run)
      end
  
    end
  end
end
