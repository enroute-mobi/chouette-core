# frozen_string_literal: true

RSpec.describe Macro::Base do

  subject { Macro::Dummy.new }
  it { is_expected.to belong_to(:macro_list).optional }
  it { is_expected.to belong_to(:macro_context).optional }

  describe ".table_name" do
    subject { described_class.table_name }
    it { is_expected.to eq("public.macros") }
  end

end
