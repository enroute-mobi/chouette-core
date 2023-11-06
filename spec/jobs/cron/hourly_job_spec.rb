# frozen_string_literal: true

RSpec.describe Cron::HourlyJob do
  describe '#cron_expression' do
    subject { described_class.cron_expression }

    it { is_expected.to eq('0 * * * *') }
  end
end
