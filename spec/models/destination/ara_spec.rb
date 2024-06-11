# frozen_string_literal: true

RSpec.describe Destination::Ara, type: :model do

  describe '#force_import' do
    subject { destination.force_import }

    context 'when use default value' do
      let(:destination) { Destination::Ara.new  }

      it { is_expected.to be_truthy }
    end

    context 'when a value is provided' do
      let(:destination) { Destination::Ara.new force_import: false  }

      it { is_expected.to be_falsey }
    end
  end

  describe '#use_ssl?' do
    subject { destination.use_ssl? }

    context 'when URL is http://test.com' do
      let(:destination) { Destination::Ara.new ara_url: 'http://test.com' }

      it { is_expected.to be_falsey }
    end

    context 'when URL is https://test.com' do
      let(:destination) { Destination::Ara.new ara_url: 'https://test.com' }

      it { is_expected.to be_truthy }
    end
  end
end
