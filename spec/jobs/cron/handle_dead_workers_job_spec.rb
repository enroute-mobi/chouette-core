# frozen_string_literal: true

RSpec.describe Cron::HandleDeadWorkersJob do
  it { is_expected.to be_a_kind_of(Cron::MinutesJob) }

  describe '#perform' do
    subject { described_class.new.perform }

    it do
      expect(Delayed::Heartbeat).to receive(:delete_timed_out_workers)
      subject
    end
  end
end
