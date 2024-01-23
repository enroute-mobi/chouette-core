# frozen_string_literal: true

RSpec.describe PointOfInterest::Base do
  let(:context) do
    Chouette.create do
      point_of_interest
    end
  end

  subject(:point_of_interest) { context.point_of_interest }

  describe '.with_position' do
    subject { described_class.with_position }

    context 'when PointOfInterest has no position' do
      before { point_of_interest.update_attribute :position, nil }
      it { is_expected.to_not include(point_of_interest) }
    end

    context 'when PointOfInterest has a position' do
      before { point_of_interest.update_attribute :position, 'POINT(0 0)' }
      it { is_expected.to include(point_of_interest) }
    end
  end

  # rubocop:disable Naming/VariableNumber
  describe '.without_address' do
    subject { described_class.without_address }

    context 'when PointOfInterest has a country' do
      before { point_of_interest.update_attribute :country, 'dummy' }
      it { is_expected.to_not include(point_of_interest) }
    end

    context 'when PointOfInterest has a address_line_1' do
      before { point_of_interest.update_attribute :address_line_1, 'dummy' }
      it { is_expected.to_not include(point_of_interest) }
    end

    context 'when PointOfInterest has a zip code' do
      before { point_of_interest.update_attribute :zip_code, 'dummy' }
      it { is_expected.to_not include(point_of_interest) }
    end

    context 'when PointOfInterest has a city name' do
      before { point_of_interest.update_attribute :city_name, 'dummy' }
      it { is_expected.to_not include(point_of_interest) }
    end

    context 'when PointOfInterest has nil country code, street name, zipcode and city name' do
      before { point_of_interest.update country: nil, address_line_1: nil, zip_code: nil, city_name: nil }
      it { is_expected.to include(point_of_interest) }
    end

    context 'when PointOfInterest has empty country code, street name, zipcode and city name' do
      before { point_of_interest.update country: '', address_line_1: '', zip_code: '', city_name: '' }
      it { is_expected.to include(point_of_interest) }
    end
  end

  describe '#address=' do
    subject { point_of_interest.address = address }

    let(:point_of_interest) { PointOfInterest::Base.new }
    let(:address) { Address.new }

    context "when Address country_name is 'dummy'" do
      before { allow(address).to receive(:country_name).and_return('dummy') }

      it { expect { subject }.to change(point_of_interest, :country).to('dummy') }
    end

    context "when Address house_number_and_street_name is 'dummy'" do
      before { allow(address).to receive(:house_number_and_street_name).and_return('dummy') }

      it { expect { subject }.to change(point_of_interest, :address_line_1).to('dummy') }
    end

    context "when Address post_code is 'dummy'" do
      before { address.post_code = 'dummy' }

      it { expect { subject }.to change(point_of_interest, :zip_code).to('dummy') }
    end

    context "when Address city_name is 'dummy'" do
      before { address.city_name = 'dummy' }

      it { expect { subject }.to change(point_of_interest, :city_name).to('dummy') }
    end
  end
  # rubocop:enable Naming/VariableNumber
end
