# frozen_string_literal: true

RSpec.describe Query::ConnectionLink do
  subject(:query) { described_class.new(context.workbench.connection_links) }

  describe '#text' do
    subject { query.text(value).scope }

    let(:context) do
      Chouette.create do
        stop_area :cl_match_departure, name: 'dmatch'
        stop_area :cl_match_arrival, name: 'amatch'
        connection_link :match, departure: :cl_match_departure, arrival: :cl_match_arrival

        stop_area :cl_other_departure, name: 'dnomatch'
        stop_area :cl_other_arrival, name: 'anomatch'
        connection_link :other, departure: :cl_other_departure, arrival: :cl_other_arrival
      end
    end

    context 'with empty string' do
      let(:value) { '' }

      it 'returns all connection links' do
        is_expected.to match_array(context.workbench.connection_links)
      end
    end

    context 'with departure name' do
      let(:value) { 'dmatch' }

      it 'returns only matching connection link' do
        is_expected.to match_array([context.connection_link(:match)])
      end

      context 'with only a part of name' do
        let(:value) { 'dma' }

        it 'still returns matching connection link' do
          is_expected.to match_array([context.connection_link(:match)])
        end
      end

      context 'with caps' do
        let(:value) { 'DMATCH' }

        it 'still returns matching connection link' do
          is_expected.to match_array([context.connection_link(:match)])
        end
      end
    end

    context 'with arrival name' do
      let(:value) { 'amatch' }

      it 'returns only matching connection link' do
        is_expected.to match_array([context.connection_link(:match)])
      end
    end
  end
end
