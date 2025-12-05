# frozen_string_literal: true

RSpec.describe Search::VehicleJourney do
  subject(:search) { described_class.new(search_attributes) }

  let(:search_attributes) { {} }

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

  describe '#search' do
    subject { search.search(scope) }

    let(:scope) { Chouette::VehicleJourney.all }

    before { context.referential.switch }

    context 'with text' do
      let(:context) do
        Chouette.create do
          vehicle_journey :vj2, published_journey_name: 'VJ2', departure_time: '12:00'
          vehicle_journey :vj1, published_journey_name: 'VJ1', departure_time: '10:00'
          vehicle_journey :vj3, published_journey_name: 'VJ3', departure_time: '11:00'
          vehicle_journey :nope, published_journey_name: 'NOPE'
        end
      end
      let(:search_attributes) { { text: 'VJ' } }

      context 'without order' do
        let(:search) { super().without_order }

        it 'returns all matching vehicle journeys' do
          is_expected.to match_array(%i[vj1 vj2 vj3].map { |vj| context.vehicle_journey(vj) })
        end
      end

      context 'with default order' do
        it 'returns all matching vehicle journeys ordered by #published_journey_name' do
          is_expected.to eq(%i[vj1 vj2 vj3].map { |vj| context.vehicle_journey(vj) })
        end
      end

      context 'with base scope' do
        context 'with SELECT (#with_departure_arrival_second_offsets)' do
          let(:scope) { super().with_departure_arrival_second_offsets }

          it 'returns all matching vehicle journeys' do
            is_expected.to match_array(%i[vj1 vj2 vj3].map { |vj| context.vehicle_journey(vj) })
          end

          it 'adds #departure_second_offset and #arrival_second_offset columns to all results' do
            is_expected.to all(respond_to(:departure_second_offset)).and(all(respond_to(:arrival_second_offset)))
          end
        end

        context 'with ORDER (#with_stops)' do
          let(:scope) { super().with_stops }

          it 'returns all matching vehicle journeys ordered by departure time' do
            is_expected.to eq(%i[vj1 vj3 vj2].map { |vj| context.vehicle_journey(vj) })
          end
        end
      end
    end
  end
end
