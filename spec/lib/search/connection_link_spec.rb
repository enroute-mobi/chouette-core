# frozen_string_literal: true

RSpec.describe Search::ConnectionLink do
  subject(:search) { described_class.new(search_attributes) }

  let(:search_attributes) { {} }

  describe '#searched_class' do
    subject { search.searched_class }

    it { is_expected.to eq(Chouette::ConnectionLink) }
  end

  describe '#query' do
    subject { search.query(scope) }

    let(:scope) { double }
    let(:query) { Query::Mock.new(scope) }

    before do
      allow(Query::ConnectionLink).to receive(:new).and_return(query)
    end

    it 'uses text' do
      search.text = 'match'
      expect(query).to receive(:text).with('match').and_return(query)
      subject
    end
  end

  describe '#search' do
    subject { search.search(context.workbench.connection_links) }

    # rails changes the alias of a join table whether there are where or order clause
    # rubocop:disable Naming/VariableNumber
    context 'join alias with where and order' do
      let(:context) do
        Chouette.create do
          stop_area :stop_area_a1, name: 'Departure A1'
          stop_area :stop_area_a2, name: 'Departure A2'
          stop_area :stop_area_b1, name: 'Departure B1'
          stop_area :stop_area_b2, name: 'Departure B2'
          stop_area :stop_area_c1, name: 'Arrival C1'
          stop_area :stop_area_c2, name: 'Arrival C2'
          stop_area :stop_area_d1, name: 'Arrival D1'
          stop_area :stop_area_d2, name: 'Arrival D2'

          connection_link :cl_ad_12, departure: :stop_area_a1, arrival: :stop_area_d2
          connection_link :cl_ad_21, departure: :stop_area_a2, arrival: :stop_area_d1
          connection_link :cl_bc_12, departure: :stop_area_b1, arrival: :stop_area_c2
          connection_link :cl_bc_21, departure: :stop_area_b2, arrival: :stop_area_c1
        end
      end

      context 'WHERE on departure' do
        let(:search_attributes) { { text: 'Departure A' } }

        it 'filters on departure name' do
          is_expected.to match_array(%i[cl_ad_12 cl_ad_21].map { |i| context.connection_link(i) })
        end
      end

      context 'WHERE on arrival' do
        let(:search_attributes) { { text: 'Arrival C' } }

        it 'filters on departure name' do
          is_expected.to match_array(%i[cl_bc_12 cl_bc_21].map { |i| context.connection_link(i) })
        end
      end

      context 'ORDER on departure' do
        let(:search_attributes) { { order: { departure: :asc } } }

        it 'orders on departure name' do
          is_expected.to eq(%i[cl_ad_12 cl_ad_21 cl_bc_12 cl_bc_21].map { |i| context.connection_link(i) })
        end
      end

      context 'ORDER on arrival' do
        let(:search_attributes) { { order: { arrival: :asc } } }

        it 'orders on arrival name' do
          is_expected.to eq(%i[cl_bc_21 cl_bc_12 cl_ad_21 cl_ad_12].map { |i| context.connection_link(i) })
        end
      end

      context 'WHERE on departure and ORDER on departure' do
        let(:search_attributes) { { text: 'Departure A', order: { departure: :asc } } }

        it 'filters on departure name and orders on departure name' do
          is_expected.to eq(%i[cl_ad_12 cl_ad_21].map { |i| context.connection_link(i) })
        end
      end

      context 'WHERE on departure and ORDER on arrival' do
        let(:search_attributes) { { text: 'Departure A', order: { arrival: :asc } } }

        it 'filters on departure name and orders on arrival name' do
          is_expected.to eq(%i[cl_ad_21 cl_ad_12].map { |i| context.connection_link(i) })
        end
      end

      context 'WHERE on arrival and ORDER on departure' do
        let(:search_attributes) { { text: 'Arrival C', order: { departure: :asc } } }

        it 'filters on arrival name and orders on departure name' do
          is_expected.to eq(%i[cl_bc_12 cl_bc_21].map { |i| context.connection_link(i) })
        end
      end

      context 'WHERE on arrival and ORDER on arrival' do
        let(:search_attributes) { { text: 'Arrival C', order: { arrival: :asc } } }

        it 'filters on arrival name and orders on arrival name' do
          is_expected.to eq(%i[cl_bc_21 cl_bc_12].map { |i| context.connection_link(i) })
        end
      end
    end
    # rubocop:enable Naming/VariableNumber
  end
end
