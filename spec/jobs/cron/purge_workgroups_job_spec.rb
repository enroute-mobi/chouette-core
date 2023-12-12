# frozen_string_literal: true

RSpec.describe Cron::PurgeWorkgroupsJob do
  it { is_expected.to be_a_kind_of(Cron::DailyJob) }

  describe '#perform' do
    subject { described_class.new.perform }

    it do
      expect(Workgroup).to receive(:purge_all)
      subject
    end
  end
end
