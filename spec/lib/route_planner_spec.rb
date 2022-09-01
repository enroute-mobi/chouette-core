# frozen_string_literal: true

RSpec.describe RoutePlanner::Config do
  subject(:config) { RoutePlanner::Config.new }

  describe '#batch' do
    subject { config.batch }

    it { is_expected.to be_a(RoutePlanner::Batch) }

    context 'when config has resolver class RoutePlanner::Resolver::TomTom' do
      before { config.resolver_classes << RoutePlanner::Resolver::TomTom }
      it { is_expected.to have_attributes(resolver_classes: a_collection_including(RoutePlanner::Resolver::TomTom)) }
    end
  end
end
