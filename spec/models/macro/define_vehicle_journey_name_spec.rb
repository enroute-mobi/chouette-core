# frozen_string_literal: true

RSpec.describe Macro::DefineVehicleJourneyName do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end
end

RSpec.describe Macro::DefineVehicleJourneyName::Run do
  it { should validate_presence_of :target_format }

  let(:macro_list_run) do
    Macro::List::Run.create referential: referential, workbench: context.workbench
  end

  let(:macro_run) do
    described_class.create(
      macro_list_run: macro_list_run,
      position: 0,
      target_format: 'Course %{public_code}'
    )
  end

  let(:context) do
    Chouette.create do
      referential do
        vehicle_journey :without_name,
                        published_journey_identifier: 'VJ-42',
                        published_journey_name: nil
        vehicle_journey :with_name,
                        published_journey_identifier: 'VJ-43',
                        published_journey_name: 'Already named'
        vehicle_journey :without_public_code,
                        published_journey_identifier: nil,
                        published_journey_name: nil
      end
    end
  end

  let(:referential) { context.referential }
  let(:without_name) { context.vehicle_journey(:without_name) }
  let(:with_name) { context.vehicle_journey(:with_name) }
  let(:without_public_code) { context.vehicle_journey(:without_public_code) }

  before { referential.switch }

  describe '#run' do
    subject { macro_run.run }

    it 'defines missing vehicle journey names from public codes' do
      expect { subject }.to change { without_name.reload.published_journey_name }
        .from(nil).to('Course VJ-42')
    end

    it 'creates a message for each renamed vehicle journey' do
      expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(2)
      expect(macro_run.macro_messages).to include(
        an_object_having_attributes(
          message_attributes: {
            'attribute_value_after_change' => 'Course VJ-42',
            'vehicle_journey_id' => without_name.get_objectid.short_id
          },
          source: without_name
        )
      )
    end

    it 'updates vehicle journeys with an existing name' do
      expect { subject }.to change { with_name.reload.published_journey_name }
        .from('Already named').to('Course VJ-43')
    end

    it 'does not change vehicle journeys without a public code' do
      expect { subject }.not_to change { without_public_code.reload.published_journey_name }
    end
  end
end
