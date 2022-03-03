RSpec.describe Control::Base do

  subject { Control::Dummy.new }
  it { is_expected.to belong_to(:control_list).required(false) }
  it { is_expected.to belong_to(:control_context).required(false) }

  describe ".table_name" do
    subject { described_class.table_name }
    it { is_expected.to eq("controls") }
  end

end
