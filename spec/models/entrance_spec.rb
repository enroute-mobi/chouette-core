# frozen_string_literal: true

describe Entrance, type: :model do
  let(:context) do
    Chouette.create do
      entrance
    end
  end

  subject(:entrance) { context.entrance }

  it { should validate_presence_of(:name) }
  it { is_expected.to enumerize(:entrance_type) }

  describe '#position_input' do
    subject { entrance.position_input }

    context 'when position is nil' do
      before { entrance.position = nil }
      it { is_expected.to be_nil }
    end

    context 'when position is POINT(2.292 48.858)' do
      before { entrance.position = 'POINT(2.292 48.858)' }
      it { is_expected.to eq('48.858 2.292') }
    end

    context "when position_input has been defined (like ')" do
      before { entrance.position_input = 'dummy' }
      it { is_expected.to eq('dummy') }
    end
  end

  describe '#position' do
    subject { entrance.position }

    [
      '48.858,2.292',
      '48.858 , 2.292',
      '48.858 : 2.292',
      '48.858 2.292',
      ' 48.858   2.292  '
    ].each do |definition|
      context "when position input is '#{definition}'" do
        before do
          entrance.position_input = definition
          entrance.valid? end
        it { is_expected.to have_attributes(y: 48.858, x: 2.292) }
      end
    end

    [
      'abc',
      '48 2',
      '1000.0 -1000.0',
      '48.858'
    ].each do |definition|
      context "when position input is '#{definition}'" do
        before do
          entrance.position_input = definition
          entrance.valid? end
        it { is_expected.to be_nil }

        it 'has an error on position_input' do
          expect(entrance.errors).to have_key(:position_input)
        end
      end
    end

    [
      nil,
      '',
      '  '
    ].each do |definition|
      context "when position input is #{definition.inspect}" do
        before do
          entrance.position_input = definition
          entrance.valid? end
        it { is_expected.to be_nil }
        it 'has no error on position_input' do
          expect(entrance.errors).to_not have_key(:position_input)
        end
      end
    end
  end

  describe '.with_position' do
    subject { described_class.with_position }

    context 'when Entrance has no position' do
      before { entrance.update_attribute :position, nil }
      it { is_expected.to_not include(entrance) }
    end

    context 'when Entrance has a position' do
      before { entrance.update_attribute :position, 'POINT(0 0)' }
      it { is_expected.to include(entrance) }
    end
  end

  describe '.without_address' do
    subject { described_class.without_address }

    context 'when Entrance has a country' do
      before { entrance.update_attribute :country, 'dummy' }
      it { is_expected.to_not include(entrance) }
    end

    context 'when Entrance has a address_line_1' do
      before { entrance.update_attribute :address_line_1, 'dummy' }
      it { is_expected.to_not include(entrance) }
    end

    context 'when Entrance has a zip code' do
      before { entrance.update_attribute :zip_code, 'dummy' }
      it { is_expected.to_not include(entrance) }
    end

    context 'when Entrance has a city name' do
      before { entrance.update_attribute :city_name, 'dummy' }
      it { is_expected.to_not include(entrance) }
    end

    context 'when Entrance has no country code, street name, zipcode or city name' do
      before { entrance.update country: nil, address_line_1: nil, zip_code: nil, city_name: nil }
      it { is_expected.to include(entrance) }
    end
  end

  describe '#address=' do
    subject { entrance.address = address }

    let(:entrance) { Entrance.new }
    let(:address) { Address.new }

    context "when Address country_name is 'dummy'" do
      before { allow(address).to receive(:country_name).and_return('dummy') }

      it { expect { subject }.to change(entrance, :country).to('dummy') }
    end

    context "when Address house_number_and_street_name is 'dummy'" do
      before { allow(address).to receive(:house_number_and_street_name).and_return('dummy') }

      it { expect { subject }.to change(entrance, :address_line_1).to('dummy') }
    end

    context "when Address post_code is 'dummy'" do
      before { address.post_code = 'dummy' }

      it { expect { subject }.to change(entrance, :zip_code).to('dummy') }
    end

    context "when Address city_name is 'dummy'" do
      before { address.city_name = 'dummy' }

      it { expect { subject }.to change(entrance, :city_name).to('dummy') }
    end
  end
end
