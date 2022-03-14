RSpec.describe Control::List::Run do
  describe ".table_name" do
    subject { described_class.table_name }
    it { is_expected.to eq("public.control_list_runs") }
  end
end
