# frozen_string_literal: true

RSpec.describe Export::Gtfs::Companies::Decorator do
  let(:company) { Chouette::Company.new }
  let(:decorator) { described_class.new company }

  describe '#timezone' do
    subject { decorator.timezone }

    context 'when Company#time_zone is "Europe/Madrid"' do
      before { company.time_zone = 'Europe/Madrid' }

      it { is_expected.to eq(company.time_zone) }
    end

    context 'when Company#time_zone isn\'t defined' do
      it { is_expected.to eq('Etc/UTC') }
    end
  end

  describe '#validate' do
    subject { decorator.validate }

    context 'when the Company has no timezone' do
      it { expect { subject }.to change(decorator, :messages).from(be_empty).to(be_one) }

      describe 'the message' do
        subject { decorator.messages.first }

        before { decorator.validate }

        it { is_expected.to have_attributes(message_key: :no_timezone) }
      end
    end
  end

  describe '#gtfs_attibutes' do
    subject { decorator.gtfs_attributes }

    context 'when Company fare_url is "dummy"' do
      before { company.fare_url = 'dummy' }

      it { is_expected.to include(fare_url: 'dummy') }
    end
  end
end

RSpec.describe Export::Gtfs::Companies do
  subject(:part) { described_class.new export }
  let(:export) { double }

  describe '#default_agency' do
    subject { part.default_agency }

    it { is_expected.to include(id: 'chouette_default') }
    it { is_expected.to include(name: 'Default Agency') }
    it { is_expected.to include(timezone: 'Etc/UTC') }
  end
end
