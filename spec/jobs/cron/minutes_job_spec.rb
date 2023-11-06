# frozen_string_literal: true

RSpec.describe Cron::MinutesJob do
  describe '#cron_expression' do
    subject { described_class.cron_expression }

    it { is_expected.to eq('*/5 * * * *') }
  end
end
