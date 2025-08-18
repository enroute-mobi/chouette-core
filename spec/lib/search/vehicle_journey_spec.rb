# frozen_string_literal: true

RSpec.describe Search::VehicleJourney do
  subject(:search) { described_class.new }

  describe '#searched_class' do
    subject { search.searched_class }

    it { is_expected.to eq(Chouette::VehicleJourney) }
  end

  describe '#query' do
    subject { search.query(scope) }

    let(:scope) { double }
    let(:query) { Query::Mock.new(scope) }

    before do
      allow(Query::VehicleJourney).to receive(:new).and_return(query)
    end

    it 'uses text' do
      search.text = 'match'
      expect(query).to receive(:text).with('match').and_return(query)
      subject
    end

    it 'uses journey_pattern_id' do
      search.journey_pattern_id = '42'
      expect(query).to receive(:journey_pattern_id).with('42').and_return(query)
      subject
    end

    it 'uses with_time_table' do
      search.with_time_table = 'false'
      expect(query).to receive(:with_time_table).with(false).and_return(query)
      subject
    end

    it 'uses departure_time_start, departure_time_end and departure_time_allow_empty' do
      search.departure_time_start = '08:00'
      search.departure_time_end = '12:00'
      search.departure_time_allow_empty = true
      expect(query).to receive(:where_departure_time_between).with('08:00', '12:00', allow_empty: true)
      subject
    end
  end
end
