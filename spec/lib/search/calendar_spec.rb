# frozen_string_literal: true

RSpec.describe Search::Calendar, type: :model do
  subject(:search) { described_class.new }

  describe '#searched_class' do
    subject { search.searched_class }

    it { is_expected.to eq(Calendar) }
  end

  describe '#query' do
    describe 'build' do
      let(:scope) { double }
      let(:query) { Query::Mock.new(scope) }

      before do
        allow(Query::Calendar).to receive(:new).and_return(query)
      end

      it 'uses Search text' do
        search.text = 'dummy'
        expect(query).to receive(:text).with('dummy').and_return(query)
        search.query(scope)
      end

      it 'uses Search shared' do
        search.shared = '1'
        expect(query).to receive(:shared).with(true).and_return(query)
        search.query(scope)
      end

      it 'uses Search contains_date' do
        search.contains_date = '2025-08-04'
        expect(query).to receive(:contains_date).with(Date.new(2025, 8, 4)).and_return(query)
        search.query(scope)
      end
    end
  end
end
