# frozen_string_literal: true

RSpec.describe Search::Equipment do
  subject(:search) { described_class.new }

  describe '#searched_class' do
    subject { search.searched_class }

    it { is_expected.to eq(Equipment) }
  end
end
