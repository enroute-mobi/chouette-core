RSpec.describe Macro::Base::Run do
  describe ".table_name" do
    subject { described_class.table_name }
    it { is_expected.to eq("public.macro_runs") }
  end
end
