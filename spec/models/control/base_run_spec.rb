RSpec.describe Control::Base::Run do
  describe ".table_name" do
    subject { described_class.table_name }
    it { is_expected.to eq("public.control_runs") }
  end
end
