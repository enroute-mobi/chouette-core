# frozen_string_literal: true

RSpec.describe Search::Company do
  subject(:search) { described_class.new }

  describe '#searched_class' do
    subject { search.searched_class }

    it { is_expected.to eq(Chouette::Company) }
  end
end
