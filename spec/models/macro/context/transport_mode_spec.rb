RSpec.describe Macro::Context::TransportMode::Run do
  let!(:organisation){create(:organisation)}
  let!(:user){create(:user, :organisation => organisation)}

  let!(:macro_list) do
    Macro::List.create! name: "Macro List 1", workbench: context.workbench
  end

  let!(:macro_context1) do
    Macro::Context::TransportMode.create! name: "Macro Context TransportMode 1", macro_list: macro_list, options: { transport_mode: "bus" }
  end

  let!(:macro_context2) do
   Macro::Context::TransportMode.create! name: "Macro Context TransportMode 2", macro_list: macro_list, options: { transport_mode: "tram" }
  end
  let!(:macro_dummy) do
    Macro::Dummy.create name: "Macro dummy 1", macro_context: macro_context1, position: 0
  end

  let(:macro_list_run) do
    Macro::List::Run.new name: "Macro List Run 1", referential: context.referential, workbench: context.workbench, original_macro_list: macro_list, creator: user
  end

  subject { macro_list_run.macro_context_runs }

  describe ".context" do

    let(:context) do
      Chouette.create do
        referential do
          journey_pattern
        end
      end
    end

    before { context.referential.switch }

    context "when macro is created with transport mode context" do
      let(:macro_context_run_names) do
        subject.map{ |context_run| context_run.name}
      end

      let(:macro_run_names) do
        subject.map{ |context_run| context_run.macro_runs.map(&:name)}.flatten
      end

      before do
        macro_list.reload
        macro_list_run.build_with_original_macro_list
        macro_list_run.save
        macro_list_run.reload
      end

      it "should return all macro_context_runs" do
        expect(macro_context_run_names).to match_array([macro_context1.name, macro_context2.name])
      end

      it "should return all macro_runs for each macro_context_runs" do
        expect(macro_run_names).to include(macro_dummy.name)
      end
    end
  end
end