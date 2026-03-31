# frozen_string_literal: true

RSpec.describe Scope::FromLines do
  subject(:scope) { described_class.new }

  describe '#collection' do
    subject { scope.collection(collection_name, current_collection: current_collection) }

    let(:global_scope) { double('global_scope') }
    let(:lines) { Chouette::Line.where(id: context.line(:line)) }
    let(:allow_lines) { allow(global_scope).to receive(:lines).and_return(lines) }

    before { scope.global_scope = global_scope }

    context 'with :line_groups' do
      let(:collection_name) { :line_groups }
      let(:current_collection) { LineGroup.all }

      let(:context) do
        Chouette.create do
          line :line
          line :other_line

          line_group :line_group, lines: %i[line]
          line_group :other_line_group, lines: %i[other_line]
        end
      end

      before { allow_lines }

      it 'returns only line groups associated to lines' do
        is_expected.to contain_exactly(context.line_group(:line_group))
      end
    end

    context 'with :companies' do
      let(:collection_name) { :companies }
      let(:current_collection) { Chouette::Company.all }

      let(:context) do
        Chouette.create do
          company :company
          company :secondary_company
          company :other_company
          company :other_secondary_company

          line :line, company: :company, secondary_companies: %i[secondary_company]
          line company: :other_company
          line secondary_companies: %i[other_secondary_company]
        end
      end

      before { allow_lines }

      it 'returns only companies associated to lines' do
        is_expected.to contain_exactly(context.company(:company), context.company(:secondary_company))
      end
    end

    context 'with :fare_products' do
      let(:collection_name) { :fare_products }
      let(:current_collection) { Fare::Product.all }

      let(:context) do
        Chouette.create do
          company :company
          company :other_company

          fare_product :fare_product, company: :company
          fare_product :fare_product_without_company, company: nil
          fare_product :other_fare_product, company: :other_company
        end
      end

      before do
        allow(global_scope).to receive(:companies).and_return(Chouette::Company.where(id: context.company(:company)))
      end

      it 'returns only fare products associated to companies' do
        is_expected.to match_array(%i[fare_product fare_product_without_company].map { |i| context.fare_product(i) })
      end
    end

    context 'with :networks' do
      let(:collection_name) { :networks }
      let(:current_collection) { Chouette::Network.all }

      let(:context) do
        Chouette.create do
          network :network
          network :other_network

          line :line, network: :network
          line network: :other_network
        end
      end

      before { allow_lines }

      it 'returns only networks associated to lines' do
        is_expected.to contain_exactly(context.network(:network))
      end
    end

    context 'with :contracts' do
      let(:collection_name) { :contracts }
      let(:current_collection) { Contract.all }

      let(:context) do
        Chouette.create do
          company :company
          line :line
          line :other_line

          contract :contract, company: :company, lines: %i[line]
          contract :other_contract, company: :company, lines: %i[other_line]
        end
      end

      before { allow_lines }

      it 'returns only contracts associated to lines' do
        is_expected.to contain_exactly(context.contract(:contract))
      end
    end

    context 'with :line_notices' do
      let(:collection_name) { :line_notices }
      let(:current_collection) { Chouette::LineNotice.all }

      let(:context) do
        Chouette.create do
          line :line
          line :other_line

          line_notice :line_notice, lines: %i[line]
          line_notice :other_line_notice, lines: %i[other_line]
        end
      end

      before { allow_lines }

      it 'returns only line notices associated to lines' do
        is_expected.to contain_exactly(context.line_notice(:line_notice))
      end
    end
  end
end
