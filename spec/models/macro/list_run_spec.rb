RSpec.describe Macro::List::Run do
  describe ".table_name" do
    subject { described_class.table_name }
    it { is_expected.to eq("public.macro_list_runs") }
  end
end
