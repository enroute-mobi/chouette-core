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
