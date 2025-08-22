# frozen_string_literal: true

RSpec.describe Query::RoutingConstraintZone do
  subject(:query) { described_class.new(scope) }

  let(:referential) { context.referential rescue nil } # rubocop:disable Style/RescueModifier
  let(:scope) { referential.routing_constraint_zones }

  before { referential&.switch }

  describe '#text' do
    subject { query.text(value).scope }

    let(:context) do
      Chouette.create do
        routing_constraint_zone :match, name: 'match', objectid: 'f95d12e0-849e-1234-bdae-6744b1f16df8'
        routing_constraint_zone :other, name: 'other', objectid: 'b6a7a917-3924-4a80-957e-832bbaac2b93'
      end
    end

    context 'with empty string' do
      let(:value) { '' }

      it 'returns all routing constraint zones' do
        is_expected.to match_array(scope)
      end
    end

    context 'with name' do
      let(:value) { 'match' }

      it 'returns only matching routing constraint zone' do
        is_expected.to match_array([context.routing_constraint_zone(:match)])
      end

      context 'with only a part of name' do
        let(:value) { 'atc' }

        it 'still returns matching routing constraint zone' do
          is_expected.to match_array([context.routing_constraint_zone(:match)])
        end
      end

      context 'with caps' do
        let(:value) { 'MATCH' }

        it 'still returns matching routing constraint zone' do
          is_expected.to match_array([context.routing_constraint_zone(:match)])
        end
      end
    end

    context 'with objectid' do
      let(:value) { 'f95d12e0-849e-1234-bdae-6744b1f16df8' }

      it 'returns only matching routing constraint zone' do
        is_expected.to match_array([context.routing_constraint_zone(:match)])
      end

      context 'with only a part of objectid' do
        let(:value) { '1234' }

        it 'still returns matching routing constraint zone' do
          is_expected.to match_array([context.routing_constraint_zone(:match)])
        end
      end
    end
  end

  describe '#route_id' do
    subject { query.route_id(value).scope }

    let(:context) do
      Chouette.create do
        route :match_route do
          routing_constraint_zone :match
        end
        route :other_route do
          routing_constraint_zone :other
        end
        route :route_without_rcz
      end
    end

    context 'with empty string' do
      let(:value) { '' }

      it 'returns all routing constraint zones' do
        is_expected.to match_array(scope)
      end
    end

    context 'with route id' do
      let(:value) { context.route(:match_route).id.to_s }

      it 'returns only matching routing constraint zone' do
        is_expected.to match_array([context.routing_constraint_zone(:match)])
      end
    end

    context 'with unknown route' do
      let(:value) { context.route(:route_without_rcz).id.to_s }

      it 'returns nothing' do
        is_expected.to be_empty
      end
    end
  end
end
