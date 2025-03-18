# frozen_string_literal: true

RSpec.describe Export::Gtfs::ConnectionLinks::Decorator do
  subject(:decorator) { described_class.new connection_link }

  let(:connection_link) { Chouette::ConnectionLink.new }

  describe '#gtfs_type' do
    subject { decorator.gtfs_type }

    it { is_expected.to eq('2') }
  end

  describe '#gtfs_min_transfer_time' do
    subject { decorator.gtfs_min_transfer_time }

    context 'when default_duration is 42' do
      before { connection_link.default_duration = 42 }

      it { is_expected.to eq(42) }
    end
  end

  describe '#gtfs_from_stop_id' do
    subject { decorator.gtfs_from_stop_id }

    context 'when departure StopArea is associated to code "42"' do
      before do
        connection_link.departure_id = 12
        allow(decorator.code_provider).to receive_message_chain(:stop_areas, :code).with(connection_link.departure_id) {
                                            '42'
                                          }
      end

      it { is_expected.to eq('42') }
    end
  end

  describe '#gtfs_to_stop_id' do
    subject { decorator.gtfs_to_stop_id }

    context 'when arrival StopArea is associated to code "42"' do
      before do
        connection_link.arrival_id = 12
        allow(decorator.code_provider).to receive_message_chain(:stop_areas, :code).with(connection_link.arrival_id) {
                                            '42'
                                          }
      end

      it { is_expected.to eq('42') }
    end
  end
end
