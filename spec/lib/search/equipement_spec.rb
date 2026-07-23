# frozen_string_literal: true

RSpec.describe Search::Equipement do
  subject(:search) { described_class.new }

  describe '#searched_class' do
    subject { search.searched_class }

    it { is_expected.to eq(Equipement) }
  end

  describe 'search by fixed' do
    let!(:context) do
      Chouette.create do
        stop_area :sa
        shape_provider do
          equipement :fixed_one, name: 'fixed one', fixed: true, stop_area: :sa
          equipement :loose_one, name: 'loose one', fixed: false, stop_area: :sa
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:scope) { workbench.shape_referential.equipements }
    let(:fixed_one) { context.equipement(:fixed_one) }
    let(:loose_one) { context.equipement(:loose_one) }

    def search_with(value)
      params = ActionController::Parameters.new('search' => { 'fixed' => value })
      Search::Equipement.from_params(params, workbench: workbench).search(scope)
    end

    it 'finds fixed equipements when searching "yes"' do
      expect(search_with('true')).to match_array([fixed_one])
    end

    it 'finds not-fixed equipements when searching "no"' do
      expect(search_with('false')).to match_array([loose_one])
    end
  end
end
