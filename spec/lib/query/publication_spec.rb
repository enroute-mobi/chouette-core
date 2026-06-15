# frozen_string_literal: true

RSpec.describe Query::Publication do
  subject(:query) { described_class.new(scope) }
  let(:scope) { context.workgroup.publications }

  describe '#text' do
    subject { query.text(value).scope }

    let(:context) do
      Chouette.create do
        referential :referential

        publication_setup :setup_alpha, name: 'Alpha export' do
          publication :pub_alice, referential: :referential, creator: 'Alice'
        end
        publication_setup :setup_beta, name: 'Beta export' do
          publication :pub_bob, referential: :referential, creator: 'Bob'
        end
      end
    end

    context 'when the value matches a creator' do
      let(:value) { 'alice' }

      it 'returns publications with a matching creator' do
        is_expected.to match_array([context.publication(:pub_alice)])
      end
    end

    context 'when the value matches a publication setup name' do
      let(:value) { 'Beta' }

      it 'returns publications of the matching setup' do
        is_expected.to match_array([context.publication(:pub_bob)])
      end
    end

    context 'when the value matches nothing' do
      let(:value) { 'no-such-thing' }

      it { is_expected.to be_empty }
    end

    context 'without value' do
      let(:value) { nil }

      it 'returns all publications' do
        is_expected.to match_array(scope)
      end
    end
  end

  describe '#publication_setup_id' do
    subject { query.publication_setup_id(value).scope }

    let(:context) do
      Chouette.create do
        referential :referential

        publication_setup :publication_setup1 do
          publication :publication1, referential: :referential
        end
        publication_setup :publication_setup2 do
          publication :publication2, referential: :referential
        end
        publication_setup :publication_setup3 do
          publication :publication3, referential: :referential
        end
      end
    end

    context 'without value' do
      let(:value) { nil }

      it 'returns all publications' do
        is_expected.to match_array(scope)
      end

      context 'as an array with an empty string' do
        let(:value) { [''] }

        it 'returns all publications' do
          is_expected.to match_array(scope)
        end
      end
    end

    context 'with value' do
      let(:value) { %i[publication_setup1 publication_setup2].map { |ps| context.publication_setup(ps).id } }

      it 'returns only matching publications' do
        is_expected.to match_array([context.publication(:publication1), context.publication(:publication2)])
      end
    end
  end
end
