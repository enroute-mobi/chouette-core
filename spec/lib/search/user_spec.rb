# frozen_string_literal: true

RSpec.describe Search::User do
  subject(:search) { described_class.new(search_attributes) }

  let(:search_attributes) { {} }

  describe '#searched_class' do
    subject { search.searched_class }

    it { is_expected.to eq(User) }
  end

  describe '#query' do
    subject { search.query(scope) }

    let(:scope) { double }
    let(:query) { Query::Mock.new(scope) }

    before do
      allow(Query::User).to receive(:new).and_return(query)
    end

    it 'uses text' do
      search.text = 'match'
      expect(query).to receive(:text).with('match').and_return(query)
      subject
    end

    it 'uses profile' do
      search.profile = %w[visitor admin]
      expect(query).to receive(:profile).with(%w[visitor admin]).and_return(query)
      subject
    end

    it 'uses states' do
      search.state = %w[pending confirmed]
      expect(query).to receive(:state).with(%w[pending confirmed]).and_return(query)
      subject
    end
  end
end
