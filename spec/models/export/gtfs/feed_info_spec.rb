# frozen_string_literal: true

RSpec.describe Export::Gtfs::FeedInfo::Decorator do
  subject(:decorator) { described_class.new(company: company, validity_period: validity_period) }

  let(:company) { Chouette::Company.new }
  let(:validity_period) { Period.from(:today) }

  describe '#start_date' do
    subject { decorator.start_date }

    context 'when Referential validity period starts on 2030-01-01' do
      let(:validity_period) { Period.from('2030-01-01') }

      it { is_expected.to eq(Date.parse('2030-01-01')) }
    end
  end

  describe '#end_date' do
    subject { decorator.end_date }

    context 'when Referential validity period starts on 2030-12-31' do
      let(:validity_period) { Period.from(:today).until('2030-12-31') }

      it { is_expected.to eq(Date.parse('2030-12-31')) }
    end
  end

  describe '#gtfs_start_date' do
    subject { decorator.gtfs_start_date }

    context 'when start date is 2030-01-15' do
      let(:validity_period) { Period.from('2030-01-15') }

      it { is_expected.to eq('20300115') }
    end
  end

  describe '#gtfs_end_date' do
    subject { decorator.gtfs_end_date }

    context 'when end date is 2030-01-15' do
      let(:validity_period) { Period.from(:today).until('2030-01-15') }

      it { is_expected.to eq('20300115') }
    end
  end

  describe '#publisher_name' do
    subject { decorator.publisher_name }

    context 'when company name is "dummy"' do
      before { company.name = 'dummy' }

      it { is_expected.to eq(company.name) }
    end

    context 'no company is not available' do
      let(:company) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#publisher_url' do
    subject { decorator.publisher_url }

    context 'when company default contact url is "http://example.com"' do
      before { company.default_contact_url = 'http://example.com' }

      it { is_expected.to eq(company.default_contact_url) }
    end

    context 'no company is not available' do
      let(:company) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#language' do
    subject { decorator.language }

    context 'when company default language is "en"' do
      before { company.default_language = 'en' }

      it { is_expected.to eq(company.default_language) }
    end

    context 'no company is not available' do
      let(:company) { nil }

      it { is_expected.to eq('fr') }
    end

    context 'when company default language is not defined' do
      before { company.default_language = '' }

      it { is_expected.to eq('fr') }
    end
  end
end
