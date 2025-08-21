# frozen_string_literal: true

RSpec.describe Search::StopAreaRoutingConstraint do
  subject(:search) { described_class.new(search_attributes) }

  let(:search_attributes) { {} }

  describe '#searched_class' do
    subject { search.searched_class }

    it { is_expected.to eq(StopAreaRoutingConstraint) }
  end

  describe '#query' do
    subject { search.query(scope) }

    let(:scope) { double }
    let(:query) { Query::Mock.new(scope) }

    before do
      allow(Query::StopAreaRoutingConstraint).to receive(:new).and_return(query)
    end

    it 'uses text' do
      search.text = 'match'
      expect(query).to receive(:text).with('match').and_return(query)
      subject
    end

    it 'uses both_way' do
      search.both_way = '1'
      expect(query).to receive(:both_way).with('1').and_return(query)
      subject
    end
  end

  describe '#search' do
    subject { search.search(context.workbench.stop_area_referential.stop_area_routing_constraints) }

    # rails changes the alias of a join table whether there are where or order clause
    # rubocop:disable Naming/VariableNumber
    context 'join alias with where and order' do
      let(:context) do
        Chouette.create do
          stop_area :stop_area_a1, name: 'From A1'
          stop_area :stop_area_a2, name: 'From A2'
          stop_area :stop_area_b1, name: 'From B1'
          stop_area :stop_area_b2, name: 'From B2'
          stop_area :stop_area_c1, name: 'To C1'
          stop_area :stop_area_c2, name: 'To C2'
          stop_area :stop_area_d1, name: 'To D1'
          stop_area :stop_area_d2, name: 'To D2'

          stop_area_routing_constraint :cl_ad_12, from: :stop_area_a1, to: :stop_area_d2
          stop_area_routing_constraint :cl_ad_21, from: :stop_area_a2, to: :stop_area_d1
          stop_area_routing_constraint :cl_bc_12, from: :stop_area_b1, to: :stop_area_c2
          stop_area_routing_constraint :cl_bc_21, from: :stop_area_b2, to: :stop_area_c1
        end
      end

      context 'WHERE on from' do
        let(:search_attributes) { { text: 'From A' } }

        it 'filters on from name' do
          is_expected.to match_array(%i[cl_ad_12 cl_ad_21].map { |i| context.stop_area_routing_constraint(i) })
        end
      end

      context 'WHERE on to' do
        let(:search_attributes) { { text: 'To C' } }

        it 'filters on from name' do
          is_expected.to match_array(%i[cl_bc_12 cl_bc_21].map { |i| context.stop_area_routing_constraint(i) })
        end
      end

      context 'ORDER on from' do
        let(:search_attributes) { { order: { from: :asc } } }

        it 'orders on from name' do
          is_expected.to eq(%i[cl_ad_12 cl_ad_21 cl_bc_12 cl_bc_21].map { |i| context.stop_area_routing_constraint(i) })
        end
      end

      context 'ORDER on to' do
        let(:search_attributes) { { order: { to: :asc } } }

        it 'orders on to name' do
          is_expected.to eq(%i[cl_bc_21 cl_bc_12 cl_ad_21 cl_ad_12].map { |i| context.stop_area_routing_constraint(i) })
        end
      end

      context 'WHERE on from and ORDER on from' do
        let(:search_attributes) { { text: 'From A', order: { from: :asc } } }

        it 'filters on from name and orders on from name' do
          is_expected.to eq(%i[cl_ad_12 cl_ad_21].map { |i| context.stop_area_routing_constraint(i) })
        end
      end

      context 'WHERE on from and ORDER on to' do
        let(:search_attributes) { { text: 'From A', order: { to: :asc } } }

        it 'filters on from name and orders on to name' do
          is_expected.to eq(%i[cl_ad_21 cl_ad_12].map { |i| context.stop_area_routing_constraint(i) })
        end
      end

      context 'WHERE on to and ORDER on from' do
        let(:search_attributes) { { text: 'To C', order: { from: :asc } } }

        it 'filters on to name and orders on from name' do
          is_expected.to eq(%i[cl_bc_12 cl_bc_21].map { |i| context.stop_area_routing_constraint(i) })
        end
      end

      context 'WHERE on to and ORDER on to' do
        let(:search_attributes) { { text: 'To C', order: { to: :asc } } }

        it 'filters on to name and orders on to name' do
          is_expected.to eq(%i[cl_bc_21 cl_bc_12].map { |i| context.stop_area_routing_constraint(i) })
        end
      end
    end
    # rubocop:enable Naming/VariableNumber
  end
end
