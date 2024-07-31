# frozen_string_literal: true

RSpec.describe Search::Workgroup do
  subject(:search) { described_class.new }

  describe '#searched_class' do
    subject { search.searched_class }

    it { is_expected.to eq(Workgroup) }
  end
end
