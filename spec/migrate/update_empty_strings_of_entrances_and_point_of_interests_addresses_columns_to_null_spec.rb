# frozen_string_literal: true

load(
  Rails.root.join(
    'db/migrate/20240123161651_update_empty_strings_of_entrances_and_point_of_interests_addresses_columns_to_null.rb'
  )
)

describe UpdateEmptyStringsOfEntrancesAndPointOfInterestsAddressesColumnsToNull, type: :migration do
  # rubocop:disable Naming/VariableNumber
  describe '#up' do
    subject { Apartment::Tenant.switch('public') { described_class.new.up } }

    shared_examples 'all_address_fields_cases' do
      context 'with all address fields filled' do
        it 'does not change attributes' do
          expect { subject }.not_to(change { object.reload.attributes })
        end
      end

      %w[country city_name zip_code address_line_1].each do |field|
        context "when only #{field} is an empty string" do
          before { object.update!(field => '') }

          it "updates #{field} to nil" do
            expect { subject }.to(
              change { object.reload.send(field) }.from('').to(nil).and(
                not_change { object.reload.attributes.except(field) }
              )
            )
          end
        end
      end

      context 'when all address fields are null' do
        before { object.update!(country: nil, city_name: nil, zip_code: nil, address_line_1: nil) }

        it 'does not change attributes' do
          expect { subject }.not_to(change { object.reload.attributes })
        end
      end
    end

    context 'with Entrance' do
      let(:context) do
        Chouette.create do
          entrance country: 'France', city_name: 'Paris', zip_code: '75000', address_line_1: 'Paris'
        end
      end
      let(:object) { context.entrance }

      before { allow(Entrance).to receive(:nullable_attributes).and_return([]) }

      include_examples 'all_address_fields_cases'
    end

    context 'with PointOfInterest' do
      let(:context) do
        Chouette.create do
          point_of_interest country: 'France', city_name: 'Paris', zip_code: '75000', address_line_1: 'Paris'
        end
      end
      let(:object) { context.point_of_interest }

      before { allow(PointOfInterest::Base).to receive(:nullable_attributes).and_return([]) }

      include_examples 'all_address_fields_cases'
    end
  end
  # rubocop:enable Naming/VariableNumber
end
