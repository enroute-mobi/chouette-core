RSpec.describe Control::List::Run do
  describe ".table_name" do
    subject { described_class.table_name }
    it { is_expected.to eq("public.control_list_runs") }
  end
end

RSpec.describe Control::List::Run::UserStatusFinalizer do
  subject(:finalizer) { described_class.new control_list_run }
  let(:control_list_run) { double }

  describe "#criticities" do
    subject { finalizer.criticities }

    let(:context) do
      Chouette.create { workbench { stop_area } }
    end

    let(:control_list) do
      context.workbench.control_lists.create!(name: "Test") do |control_list|
        control_list.controls << Control::Dummy.new(criticity: :error)
        control_list.controls << Control::Dummy.new(criticity: :warning)
      end
    end

    let(:control_list_run) do
      attributes = { name: "Test", original_control_list: control_list, creator: "test", workbench: context.workbench}
      source = context.stop_area

      context.workbench.control_list_runs.create!(attributes) do |control_list_run|
        control_list_run.build_with_original_control_list

        control_list_run.control_runs.each do |control_run|
          2.times do
            control_run.control_messages.build(criticity: control_run.criticity, source: source)
          end
        end
      end
    end

    it "returns all kind of criticities present into the Control::List::Run messages" do
      is_expected.to eq(%w{error warning})
    end
  end

  describe "#worst_criticity" do
    subject { finalizer.worst_criticity }

    before { allow(finalizer).to receive(:criticities).and_return(criticities) }

    [
      [ %w{warning error}, "error" ],
      [ %w{error warning}, "error" ],
      [ %w{error}, "error" ],
      [ %w{warning}, "warning" ],
      [ [], nil ],
    ].each do |criticities, expected|
      context "if criticities are #{criticities.inspect}" do
        let(:criticities) { criticities }
        it { is_expected.to eq(expected) }
      end
    end
  end

  describe "#user_status" do
    subject { finalizer.user_status }

    before { allow(finalizer).to receive(:worst_criticity).and_return(worst_criticity) }

    [
      [ "error", Operation.user_status.failed ],
      [ "warning", Operation.user_status.warning ],
      [ nil, Operation.user_status.successful ],
    ].each do |worst_criticity, expected|
      context "if worst criticity is #{worst_criticity}" do
        let(:worst_criticity) { worst_criticity }
        it { is_expected.to eq(expected) }
      end
    end
  end
end
