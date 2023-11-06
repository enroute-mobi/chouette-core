# frozen_string_literal: true

RSpec.describe Cron::DailyJob do
  describe '#cron_expression' do
    subject { described_class.cron_expression }

    it { is_expected.to eq('0 3 * * *') }
  end
end
