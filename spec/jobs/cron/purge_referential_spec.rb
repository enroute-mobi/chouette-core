# frozen_string_literal: true

RSpec.describe Cron::PurgeReferentialJob do
  it { is_expected.to be_a_kind_of(Cron::DailyJob) }

  describe '#perform' do
    subject { described_class.new.perform }

    it do
      expect(Referential).to receive(:clean!)
      subject
    end
  end
end
