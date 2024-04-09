# frozen_string_literal: true

RSpec.describe Macro::DefineFrenchCodeInsee do
  it { should validate_presence_of :target_model }
  it do
    should enumerize(:target_model).in(
      %w[StopArea Entrance PointOfInterest]
    )
  end

  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::DefineFrenchCodeInsee::Run do
    let(:workbench) { context.workbench }
    let(:stop_area) { context.stop_area(:stop_area) }

    let(:macro_list_run) do
      Macro::List::Run.create workbench: workbench
    end

    subject(:macro_run) do
      described_class.create(
        macro_list_run: macro_list_run,
        options: { target_model: 'StopArea' },
        position: 0
      )
    end

    describe '.run' do
      subject { macro_run.run }

      context 'when the stop area has no postal region' do
        before(:each) do
          stub_request(:get, url).to_return(status: 200, body: insee_postal_region_response)
        end

        context 'when the postion is in France' do
          let(:context) do
            Chouette.create do
              stop_area :stop_area, name: 'stop area', latitude: 47.2372428, longitude: -1.5767392
            end
          end

          let(:url) { 'https://geo.api.gouv.fr/communes?lat=47.2372428&lon=-1.5767392' }
          let(:insee_postal_region_response) { read_fixture('insee-postal-region-response.json') }

          it 'should update postal_region into stop area' do
            expect do
              subject
              stop_area.reload
            end.to change(stop_area, :postal_region).to('44109')
          end

          it 'creates a message for each stop area' do
            subject

            expected_message = an_object_having_attributes(
              criticity: 'info',
              message_attributes: {
                'name' => stop_area.name,
                'postal_region' => '44109'
              },
              source: stop_area
            )
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context 'when the postion is not in France' do
          let(:context) do
            Chouette.create do
              stop_area :stop_area, name: 'stop area', latitude: 36.868446, longitude: -116.784582
            end
          end

          let(:url) { 'https://geo.api.gouv.fr/communes?lat=36.868446&lon=-116.784582' }
          let(:insee_postal_region_response) { read_fixture('insse-postal-region-empty-response.json') }

          it 'should not update postal_region into stop area' do
            expect do
              subject
              stop_area.reload
            end.not_to change(stop_area, :postal_region)
          end
        end
      end
    end
  end
end
