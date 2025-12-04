# frozen_string_literal: true

RSpec.describe Cron::DataFreezeReferentialsJob do
  it { is_expected.to be_a_kind_of(Cron::DailyJob) }

  describe '#perform' do
    subject { described_class.new.perform }

    it 'freezes data freeze candidates' do
      data_freeze_candidates = double(:data_freeze_candidates)
      expect(Referential).to receive(:data_freeze_candidates).and_return(data_freeze_candidates)

      referential = double(:referential)
      expect(data_freeze_candidates).to receive(:find_each).and_yield(referential)

      expect(referential).to receive(:data_freeze)

      subject
    end
  end
end
