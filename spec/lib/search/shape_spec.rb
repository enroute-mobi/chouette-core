# frozen_string_literal: true

RSpec.describe Search::Shape, type: :model do
  subject(:search) { described_class.new }

  describe '#searched_class' do
    subject { search.searched_class }

    it { is_expected.to eq(Shape) }
  end

  describe '#query' do
    describe 'build' do
      let(:scope) { double }
      let(:query) { Query::Mock.new(scope) }

      before do
        allow(Query::Shape).to receive(:new).and_return(query)
      end

      it 'uses Search text' do
        search.text = 'dummy'
        expect(query).to receive(:text).with('dummy').and_return(query)
        search.query(scope)
      end
    end
  end
end
