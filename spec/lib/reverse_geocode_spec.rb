# frozen_string_literal: true

RSpec.describe ReverseGeocode::Config do
  subject(:config) { ReverseGeocode::Config.new }

  describe '#batch' do
    subject { config.batch }

    it { is_expected.to be_a(ReverseGeocode::Batch) }

    context 'when config has resolver class ReverseGeocode::Resolver::TomTom' do
      before { config.resolver_classes << ReverseGeocode::Resolver::TomTom }
      it { is_expected.to have_attributes(resolver_classes: a_collection_including(ReverseGeocode::Resolver::TomTom)) }
    end

    context 'when config has resolver class ReverseGeocode::Resolver::FrenchBAN' do
      before { config.resolver_classes << ReverseGeocode::Resolver::FrenchBAN }
      it do
        is_expected.to have_attributes(resolver_classes: a_collection_including(ReverseGeocode::Resolver::FrenchBAN))
      end
    end
  end
end

RSpec.describe ReverseGeocode::Resolver::Cache do
  subject(:cache_resolver) { described_class.new(next_instance) }
  let(:next_instance) { nil }

  describe '#cache' do
    subject { cache_resolver.cache }

    context 'when next_instance is TomTom' do
      let(:next_instance) { ReverseGeocode::Resolver::TomTom.new }

      it 'uses a tomtom specific namespace' do
        expect(subject.namespace).to eq('reverse-geocode-tom_tom')
      end
    end

    context 'when next_instance is FrenchBAN' do
      let(:next_instance) { ReverseGeocode::Resolver::FrenchBAN.new }

      it 'uses a french_ban specific namespace' do
        expect(subject.namespace).to eq('reverse-geocode-french_ban')
      end
    end
  end
end