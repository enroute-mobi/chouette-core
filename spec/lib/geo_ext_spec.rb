# frozen_string_literal: true

RSpec.describe Geo::Position do
  include Geo::Matchers

  subject(:position) { Geo::Position.new(latitude: 48.8606146, longitude: 2.2893418) }

  describe '#endpoint' do
    subject { position.endpoint heading: heading, distance: distance }

    context 'when distance is 250m' do
      let(:distance) { 250 }

      context 'with any heading' do
        let(:heading) { rand(0..360) }

        it { is_expected.to be_distant_of(distance).of(position) }
      end

      context 'when heading is north' do
        let(:heading) { 0 }

        it { is_expected.to be_distant_of(distance).of(position) }
        it { is_expected.to have_attributes(latitude: be > position.latitude) }
        it { is_expected.to have_attributes(longitude: be_within(0.0000001).of(position.longitude)) }
      end

      context 'when heading is south' do
        let(:heading) { 180 }

        it { is_expected.to be_distant_of(distance).of(position) }
        it { is_expected.to have_attributes(latitude: be < position.latitude) }
        it { is_expected.to have_attributes(longitude: be_within(0.0000001).of(position.longitude)) }
      end

      context 'when heading is east' do
        let(:heading) { 90 }

        it { is_expected.to be_distant_of(distance).of(position) }
        it { is_expected.to have_attributes(latitude: be_within(0.0000001).of(position.latitude)) }
        it { is_expected.to have_attributes(longitude: be > position.longitude) }
      end

      context 'when heading is west' do
        let(:heading) { 270 }

        it { is_expected.to be_distant_of(distance).of(position) }
        it { is_expected.to have_attributes(latitude: be_within(0.0000001).of(position.latitude)) }
        it { is_expected.to have_attributes(longitude: be < position.longitude) }
      end
    end
  end
end
