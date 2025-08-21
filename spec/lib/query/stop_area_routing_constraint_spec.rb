# frozen_string_literal: true

RSpec.describe Query::StopAreaRoutingConstraint do
  subject(:query) { described_class.new(scope) }

  let(:scope) { context.workbench.stop_area_referential.stop_area_routing_constraints }

  describe '#text' do
    subject { query.text(value).scope }

    let(:context) do
      Chouette.create do
        stop_area :cl_match_from, name: 'fmatch'
        stop_area :cl_match_to, name: 'tmatch'
        stop_area_routing_constraint :match, from: :cl_match_from, to: :cl_match_to

        stop_area :cl_other_from, name: 'fnomatch'
        stop_area :cl_other_to, name: 'tnomatch'
        stop_area_routing_constraint :other, from: :cl_other_from, to: :cl_other_to
      end
    end

    context 'with empty string' do
      let(:value) { '' }

      it 'returns all stop area routing constraints' do
        is_expected.to match_array(scope)
      end
    end

    context 'with from sname' do
      let(:value) { 'fmatch' }

      it 'returns only matching routing constraint' do
        is_expected.to match_array([context.stop_area_routing_constraint(:match)])
      end

      context 'with only a part of name' do
        let(:value) { 'fma' }

        it 'still returns matching routing constraint' do
          is_expected.to match_array([context.stop_area_routing_constraint(:match)])
        end
      end

      context 'with caps' do
        let(:value) { 'FMATCH' }

        it 'still returns matching routing constraint' do
          is_expected.to match_array([context.stop_area_routing_constraint(:match)])
        end
      end
    end

    context 'with to name' do
      let(:value) { 'tmatch' }

      it 'returns only matching routing constraint' do
        is_expected.to match_array([context.stop_area_routing_constraint(:match)])
      end

      context 'with only a part of name' do
        let(:value) { 'tma' }

        it 'still returns matching routing constraint' do
          is_expected.to match_array([context.stop_area_routing_constraint(:match)])
        end
      end

      context 'with caps' do
        let(:value) { 'TMATCH' }

        it 'still returns matching routing constraint' do
          is_expected.to match_array([context.stop_area_routing_constraint(:match)])
        end
      end
    end
  end

  describe '#both_way' do
    subject { query.both_way(value).scope }

    let(:context) do
      Chouette.create do
        stop_area :stop_area1
        stop_area :stop_area2

        stop_area_routing_constraint :both_way, from: :stop_area1, to: :stop_area2, both_way: true
        stop_area_routing_constraint :not_both_way, from: :stop_area1, to: :stop_area2, both_way: false
      end
    end

    context 'with empty string' do
      let(:value) { '' }

      it 'returns all stop area routing constraints' do
        is_expected.to match_array(scope)
      end
    end

    context 'when value is "1"' do
      let(:value) { '1' }

      it 'return only matching stop area routing constraint' do
        is_expected.to match_array([context.stop_area_routing_constraint(:both_way)])
      end
    end

    context 'when value is "0"' do
      let(:value) { '0' }

      it 'return only matching stop area routing constraint' do
        is_expected.to match_array([context.stop_area_routing_constraint(:not_both_way)])
      end
    end
  end
end
