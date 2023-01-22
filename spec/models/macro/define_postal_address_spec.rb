# frozen_string_literal: true

RSpec.describe Macro::DefinePostalAddress do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::DefinePostalAddress::Run do
    let(:context) do
      Chouette.create do
        stop_area :stop_area, name: 'stop area', latitude: 52.157831, longitude: 5.223776
        referential
      end
    end

    let(:workgroup) { context.workgroup }
    let(:referential) { context.referential }
    let(:workbench) { referential.workbench }
    let(:stop_area) { context.stop_area(:stop_area) }

    let(:macro_list_run) do
      Macro::List::Run.create referential: referential, workbench: workbench
    end
    subject(:macro_run) do
      Macro::DefinePostalAddress::Run.create(
        macro_list_run: macro_list_run,
        options: { target_model: 'StopArea' },
        position: 0
      )
    end

    describe '.run' do
      subject { macro_run.run }

      before do
        referential.switch

        workgroup.owner.update features: ['reverse_geocode']
      end

      context 'when the stop area has no address' do
        before(:each) do
          reverse_geocode_response = File.read('spec/fixtures/tomtom-reverse-geocode-response.json')
          stub_request(:post, 'https://api.tomtom.com/search/2/batch/sync.json?key=mock_tomtom_api_key').to_return(
            status: 200, body: reverse_geocode_response
          )
        end

        it 'should update address into stop area' do
          expect do
            subject
            stop_area.reload
          end.to change(stop_area, :street_name).to('100 Santa Cruz Street')
                                                .and(change(stop_area, :country_code).to('US'))
                                                .and(change(stop_area, :zip_code).to('95065'))
                                                .and(change(stop_area, :city_name).to('Santa Cruz'))
        end

        it 'creates a message for each journey_pattern' do
          subject
          # Address.new house_number: "100 Santa Cruz Street 95065 Santa Cruz"

          expected_message = an_object_having_attributes(
            criticity: 'info',
            message_attributes: {
              'name' => stop_area.name,
              'address' => '100 Santa Cruz Street, 95065, Santa Cruz, États-Unis'
            },
            source: stop_area
          )
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end
    end
  end
end
