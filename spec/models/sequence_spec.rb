RSpec.describe Sequence do

  it { is_expected.to validate_presence_of(:name) }

  describe "#values" do

    context 'with sequence_type range_sequence' do
      let(:sequence) { Sequence.new name: 'range sequence', sequence_type: :range_sequence, range_start: 1, range_end: 1000 }

      it 'and offset 50 and limit 100 it should return values from 50 to 150' do
        expect(sequence.values(offset: 50, limit: 100)).to eq((50..150).to_a)
      end
    end

    context 'with sequence_type static_list' do
      let(:sequence) { Sequence.new name: 'static list', sequence_type: :static_list, static_list: ("a".."z").to_a }

      it 'and offset 2 and limit 10 it should return letter values from c to k' do
        expect(sequence.values(offset: 2, limit: 10)).to eq(("c".."k").to_a)
      end
    end

  end

end
