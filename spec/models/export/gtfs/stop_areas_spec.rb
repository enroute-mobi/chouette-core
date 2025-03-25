# frozen_string_literal: true

RSpec.describe Export::Gtfs::StopAreas::Decorator do
  let(:stop_area) { Chouette::StopArea.new }
  subject(:decorator) { described_class.new stop_area }

  describe '#gtfs_platform_code' do
    subject { decorator.gtfs_platform_code }

    context 'when public code is nil' do
      before { stop_area.public_code = nil }
      it { is_expected.to be_nil }
    end

    context "when public code is ''" do
      before { stop_area.public_code = '' }
      it { is_expected.to be_nil }
    end

    context "when public code is 'dummy" do
      before { stop_area.public_code = 'dummy' }
      it { is_expected.to eq('dummy') }
    end
  end

  describe '#gtfs_wheelchair_boarding' do
    subject { decorator.gtfs_wheelchair_boarding }

    [
      [nil, '0'],
      %w[unknown 0],
      %w[yes 1],
      %w[no 2]
    ].each do |wheelchair_accessibility, expected|
      context "when wheelchair_accessibility is #{wheelchair_accessibility.inspect}" do
        before { stop_area.wheelchair_accessibility = wheelchair_accessibility }
        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#default_fare_zone' do
    subject { decorator.default_fare_zone }

    context 'when the StopArea has no Fare Zone' do
      it { is_expected.to be_nil }
    end

    context 'when the StopArea has one Fare Zone' do
      let(:fare_zone) { Fare::Zone.new }

      before { stop_area.fare_zones << fare_zone }

      it { is_expected.to eq(fare_zone) }
    end

    context 'when the StopArea has several Fare Zones' do
      let(:fare_zone) { Fare::Zone.new name: 'First' }

      before do
        stop_area.fare_zones << fare_zone
        stop_area.fare_zones << Fare::Zone.new
      end

      it { is_expected.to eq(fare_zone) }
    end
  end

  describe '#gtfs_zone_id' do
    subject { decorator.gtfs_zone_id }

    context 'when default FareZone is nil' do
      before { allow(decorator).to receive(:default_fare_zone).and_return(nil) }

      it { is_expected.to be_nil }
    end

    context 'when the CodeProvider returns 42 for the default FareZone', skip: 'CHOUETTE-4496' do
      before do
        fare_zone = Fare::Zone.new
        allow(decorator).to receive(:default_fare_zone).and_return(fare_zone)
        allow(decorator.code_provider).to receive(:code).with(fare_zone).and_return('42')
      end

      it { is_expected.to eq('42') }
    end

    # TODO CHOUETTE-4496 temporary
    context 'with default_fare_zone' do
      let(:context) do
        Chouette.create do
          code_space :code_space1, short_name: 'cs1'
          code_space :code_space2, short_name: 'cs2'
          code_space :no_code_space, short_name: 'ncs'

          fare_zone :fare_zone, uuid: '1a9c0d69-e8be-46fb-a28c-0e139fb74539', codes: { 'cs1' => 'V1', 'cs2' => 'V2' }
          fare_zone :other_fare_zone, codes: { 'cs1' => 'V1' }
        end
      end
      let(:fare_zone) { context.fare_zone(:fare_zone) }
      let(:code_space) { nil }

      before do
        allow(decorator).to receive(:default_fare_zone).and_return(fare_zone)
        allow(decorator).to receive(:code_space).and_return(code_space)
      end

      context 'when export has no code_space' do
        it 'returns fare zone uuid' do
          is_expected.to eq('1a9c0d69-e8be-46fb-a28c-0e139fb74539')
        end
      end

      context 'when export has a code space' do
        let(:code_space) { context.code_space(:code_space1) }

        it 'returns the fare zone code in this code space' do
          is_expected.to eq('V1')
        end

        context 'but there are 2 fare zones with the same values in this code space' do
          let(:code_space) { context.code_space(:code_space2) }

          it 'still returns the fare zone code in this code space' do
            is_expected.to eq('V2')
          end
        end

        context 'but the fare zone has no code in this code space' do
          let(:code_space) { context.code_space(:no_code_space) }

          it 'returns fare zone uuid' do
            is_expected.to eq('1a9c0d69-e8be-46fb-a28c-0e139fb74539')
          end
        end
      end
    end
  end

  describe '#gtfs_attributes' do
    subject { decorator.gtfs_attributes }

    context "when gtfs_platform_code is 'dummy'" do
      before { allow(decorator).to receive(:gtfs_platform_code).and_return('dummy') }

      it { is_expected.to include(platform_code: 'dummy') }
    end

    context "when gtfs_wheelchair_boarding is 'dummy'" do
      before { allow(decorator).to receive(:gtfs_wheelchair_boarding).and_return('dummy') }

      it { is_expected.to include(wheelchair_boarding: 'dummy') }
    end

    context "when gtfs_zone_id is 'dummy'" do
      before { allow(decorator).to receive(:gtfs_zone_id).and_return('dummy') }

      it { is_expected.to include(zone_id: 'dummy') }
    end
  end

  describe '#gtfs_timezone' do
    subject { decorator.gtfs_timezone }
    before { stop_area.time_zone = 'StopArea timezone' }

    context 'when StopArea has parent station' do
      before { allow(decorator).to receive(:has_parent_station?).and_return(true) }

      it { is_expected.to be_nil }
    end

    context 'when StopArea has no parent station' do
      before { allow(decorator).to receive(:has_parent_station?).and_return(false) }

      it { is_expected.to eq(stop_area.time_zone) }
    end
  end

  describe '#gtfs_parent_station' do
    subject { decorator.gtfs_parent_station }

    context 'when StopArea parent is associated to code "42"' do
      before do
        stop_area.parent_id = 12
        allow(decorator.code_provider).to receive_message_chain(:stop_areas, :code).with(stop_area.parent_id) { '42' }
      end

      it { is_expected.to eq('42') }
    end
  end

  describe '#gtfs_stop_code' do
    subject { decorator.gtfs_stop_code }

    context 'when public_code_space is not defined' do
      it { is_expected.to be_nil }
    end

    context 'when public_code_space is "test"' do
      before { decorator.public_code_space = code_space }
      let(:code_space) { CodeSpace.new name: 'test', id: 42 }

      context 'when StopArea has a code test:dummy' do
        before do
          stop_area.codes << Code.new(value: 'wrong')
          stop_area.codes << Code.new(code_space: code_space, value: 'dummy')
        end

        it { is_expected.to eq('dummy') }
      end

      context 'when StopArea has no code test' do
        it { is_expected.to be_nil }
      end
    end
  end

  describe '#gtfs_location_type' do
    subject { decorator.gtfs_location_type }

    context 'when StopArea is a Quay' do
      before { allow(stop_area).to receive(:quay?) { true } }

      it { is_expected.to eq(0) }
    end

    context 'when StopArea isn\'t a Quay' do
      before { allow(stop_area).to receive(:quay?) { false } }

      it { is_expected.to eq(1) }
    end
  end

  describe '#has_parent_station?' do
    subject { decorator.has_parent_station? }

    context 'when StopArea is a Quay' do
      before { allow(stop_area).to receive(:quay?) { true } }

      context 'when StopArea parent_id is present' do
        before { stop_area.parent_id = 42 }

        it { is_expected.to be_truthy }
      end

      context 'when StopArea parent_id is not present' do
        it { is_expected.to be_falsy }
      end
    end

    context 'when StopArea isn\'t a Quay' do
      before { allow(stop_area).to receive(:quay?) { false } }

      it { is_expected.to be_falsy }
    end
  end
end
