# frozen_string_literal: true

RSpec.describe Scope::FromFareProducts do
  subject(:scope) { described_class.new }

  describe '#collection' do
    subject { scope.collection(collection_name, current_collection: current_collection) }

    let(:global_scope) { double('global_scope') }
    let(:fare_products) { Fare::Product.where(id: context.fare_product(:fare_product)) }

    before do
      scope.global_scope = global_scope
      allow(global_scope).to receive(:fare_products).and_return(fare_products)
    end

    context 'with :fare_validities' do
      let(:collection_name) { :fare_validities }
      let(:current_collection) { Fare::Validity.all }

      let(:context) do
        Chouette.create do
          company :company
          fare_product :fare_product, company: :company
          fare_product :other_fare_product, company: :company

          fare_validity :fare_validity, products: %i[fare_product]
          fare_validity :other_fare_validity, products: %i[other_fare_product]
        end
      end

      it 'returns only fare validities associated to fare products' do
        is_expected.to contain_exactly(context.fare_validity(:fare_validity))
      end
    end
  end
end
