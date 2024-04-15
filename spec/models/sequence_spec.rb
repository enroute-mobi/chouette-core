# frozen_string_literal: true

RSpec.describe Sequence do
  it { is_expected.to validate_presence_of(:name) }

  describe '#values' do
    context 'with sequence_type range_sequence' do
      let(:sequence) do
        Sequence.new name: 'range sequence', sequence_type: :range_sequence, range_start: range_start, range_end: 1000
      end

      context 'when range start is 1' do
        let(:range_start) { 1 }

        it 'and offset 50 and limit 100 it should return values from 50 to 150' do
          expect(sequence.values(offset: 50, limit: 100)).to eq((50..150).to_a)
        end
      end

      context 'when range start is 100' do
        let(:range_start) { 100 }

        it 'and offset 1 and limit 100 it should return values from 100 to 200' do
          expect(sequence.values(offset: 1, limit: 100)).to eq((100..200).to_a)
        end
      end
    end

    context 'with sequence_type static_list from a to z' do
      let(:sequence) { Sequence.new name: 'static list', sequence_type: :static_list, static_list: ('a'..'z').to_a }

      it 'and offset 2 and limit 10 it should return letter values from b to k' do
        expect(sequence.values(offset: 2, limit: 10)).to eq(('b'..'k').to_a)
      end
    end

    context 'with sequence_type static_list []' do
      let(:sequence) { Sequence.new name: 'static list', sequence_type: :static_list, static_list: [] }

      it 'and offset 2 and limit 10 it should return []' do
        expect(sequence.values(offset: 2, limit: 10)).to eq([])
      end
    end
  end
end
