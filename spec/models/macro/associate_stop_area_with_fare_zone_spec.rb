# frozen_string_literal: true

RSpec.describe Macro::AssociateStopAreaWithFareZone do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::AssociateStopAreaWithFareZone::Run do
    let(:macro_run) do
      described_class.create(
        macro_list_run: macro_list_run,
        target_attribute: target_attribute,
        position: 0
      )
    end

    let(:macro_list_run) do
      Macro::List::Run.create(referential: referential, workbench: workbench)
    end

    let(:referential) { nil }
    let(:workbench) { context.workbench }
    let(:stop_area) { context.stop_area(:stop_area) }

    let(:expected_message) do
      an_object_having_attributes(
        message_attributes: {
          'stop_area_name' => 'Stop Area',
          'fare_zone_name' => 'Fare Zone'
        },
        source: stop_area
      )
    end

    describe '#run' do
      subject { macro_run.run }

      context 'when target_attribute is zip_code' do
        let(:target_attribute) { 'zip_code' }

        let(:context) do
          Chouette.create do
            stop_area :stop_area, name: 'Stop Area', zip_code: '44300'
            stop_area :other_stop_area, zip_code: nil

            fare_zone :fare_zone, name: 'Fare Zone' do
              fare_geographic_reference :fare_geographic_reference, short_name: '44300'
            end
          end
        end

        it 'creates a message for the Stop Area' do
          subject

          expect(macro_run.macro_messages).to include(expected_message)
        end

        it 'should associate the Stop Area with the Fare Zone' do
          expect { subject }.to change { stop_area.fare_zones.count }.from(0).to(1)
        end
      end

      context 'when target_attribute is city_name' do
        let(:target_attribute) { 'city_name' }

        let(:context) do
          Chouette.create do
            stop_area :stop_area, name: 'Stop Area', city_name: 'Nantes'
            stop_area :other_stop_area, zip_code: nil

            fare_zone :fare_zone, name: 'Fare Zone' do
              fare_geographic_reference :fare_geographic_reference, short_name: 'Nantes'
            end
          end
        end

        it 'creates a message for the Stop Area' do
          subject

          expect(macro_run.macro_messages).to include(expected_message)
        end

        it 'should associate the Stop Area with the Fare Zone' do
          expect { subject }.to change { stop_area.fare_zones.count }.from(0).to(1)
        end
      end

      context 'when target_attribute is postal_region' do
        let(:target_attribute) { 'postal_region' }

        let(:context) do
          Chouette.create do
            stop_area :stop_area, name: 'Stop Area', postal_region: '44'
            stop_area :other_stop_area, zip_code: nil

            fare_zone :fare_zone, name: 'Fare Zone' do
              fare_geographic_reference :fare_geographic_reference, short_name: '44'
            end
          end
        end

        it 'creates a message for the Stop Area' do
          subject

          expect(macro_run.macro_messages).to include(expected_message)
        end

        it 'should associate the Stop Area with the Fare Zone' do
          expect { subject }.to change { stop_area.fare_zones.count }.from(0).to(1)
        end
      end

      context 'when target_attribute is country_code' do
        let(:target_attribute) { 'country_code' }

        let(:context) do
          Chouette.create do
            stop_area :stop_area, name: 'Stop Area', country_code: 'FR'
            stop_area :other_stop_area, zip_code: nil

            fare_zone :fare_zone, name: 'Fare Zone' do
              fare_geographic_reference :fare_geographic_reference, short_name: 'FR'
            end
          end
        end

        it 'creates a message for the Stop Area' do
          subject

          expect(macro_run.macro_messages).to include(expected_message)
        end

        it 'should associate the Stop Area with the Fare Zone' do
          expect { subject }.to change { stop_area.fare_zones.count }.from(0).to(1)
        end
      end
    end
  end
end
