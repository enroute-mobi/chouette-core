# frozen_string_literal: true

RSpec.describe Search::RoutingConstraintZone do
  subject(:search) { described_class.new(search_attributes) }

  let(:search_attributes) { {} }
  let(:referential) { context.referential rescue nil } # rubocop:disable Style/RescueModifier

  before { referential&.switch }

  describe '#searched_class' do
    subject { search.searched_class }

    it { is_expected.to eq(Chouette::RoutingConstraintZone) }
  end

  describe '#query' do
    subject { search.query(scope) }

    let(:scope) { double }
    let(:query) { Query::Mock.new(scope) }

    before do
      allow(Query::RoutingConstraintZone).to receive(:new).and_return(query)
    end

    it 'uses text' do
      search.text = 'match'
      expect(query).to receive(:text).with('match').and_return(query)
      subject
    end

    it 'uses route_id' do
      search.route_id = '42'
      expect(query).to receive(:route_id).with('42').and_return(query)
      subject
    end
  end

  describe '#search' do
    subject { search.search(scope) }

    let(:scope) { referential.routing_constraint_zones }

    context 'with order' do
      let(:search_attributes) { { order: { attribute => direction } } }

      context 'on stop_points_count' do
        let(:attribute) { 'stop_points_count' }
        let(:context) do
          Chouette.create do
            route stop_count: 5 do
              routing_constraint_zone :two, stop_points_count: 2
              routing_constraint_zone :four, stop_points_count: 4
              routing_constraint_zone :three, stop_points_count: 3
            end
          end
        end

        context 'ascending' do
          let(:direction) { :asc }

          it { is_expected.to eq(%i[two three four].map { |rcz| context.routing_constraint_zone(rcz) }) }
        end

        context 'descending' do
          let(:direction) { :desc }

          it { is_expected.to eq(%i[four three two].map { |rcz| context.routing_constraint_zone(rcz) }) }
        end
      end
    end
  end

  describe '#candidate_routes' do
    subject { search.candidate_routes }

    let(:context) do
      Chouette.create do
        referential do
          route :route1
          route :route2
          route :route3
        end
      end
    end
    let(:search_attributes) { { referential: referential } }

    it 'returns all routes of the referential' do
      is_expected.to match_array(%i[route1 route2 route3].map { |r| context.route(r) })
    end
  end

  describe '#routes' do
    subject { search.routes }

    let(:context) do
      Chouette.create do
        referential do
          route :route
          route :route1
          route :route2
        end
      end
    end
    let(:search_attributes) { { referential: referential, route_id: route_id } }

    context 'when route_id is empty' do
      let(:route_id) { '' }

      it 'is empty' do
        is_expected.to be_empty
      end
    end

    context 'when route_id is a route id in referential' do
      let(:route_id) { context.route(:route).id.to_s }

      it 'returns an array including said route' do
        is_expected.to match_array([context.route(:route)])
      end
    end

    context 'when route_id is unknown' do
      let(:route_id) { '0' }

      it 'is empty' do
        is_expected.to be_empty
      end
    end
  end
end
