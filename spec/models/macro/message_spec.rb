RSpec.describe Macro::Message do
  describe ".table_name" do
    subject { described_class.table_name }
    it { is_expected.to eq("public.macro_messages") }
  end
end
