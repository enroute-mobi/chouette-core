RSpec.describe Control::List::Run do
  describe ".table_name" do
    subject { described_class.table_name }
    it { is_expected.to eq("control_list_runs") }
  end
end
