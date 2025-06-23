# frozen_string_literal: true

RSpec.describe Macro::Message do
  let(:message) { Macro::Message.new }

  describe '.table_name' do
    subject { described_class.table_name }
    it { is_expected.to eq('public.macro_messages') }
  end
end
