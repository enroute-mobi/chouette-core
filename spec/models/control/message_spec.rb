RSpec.describe Control::Message do
  describe ".table_name" do
    subject { described_class.table_name }
    it { is_expected.to eq("public.control_messages") }
  end
end
