# frozen_string_literal: true

RSpec.describe Macro::DeleteVehicleJourneys do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::DeleteVehicleJourneys::Run do
    let(:macro_run) { Macro::DeleteVehicleJourneys::Run.create macro_list_run: macro_list_run, position: 0 }

    let(:macro_list_run) do
      Macro::List::Run.create referential: context.referential, workbench: context.workbench
    end

    describe '#run' do
      subject { macro_run.run }

      let(:context) do
        Chouette.create do
          time_table :first
          time_table :second
          time_table :third

          # create 2 vehicle journeys
          vehicle_journey time_tables: %i[first second]
          vehicle_journey time_tables: %i[first third]
        end
      end

      let(:referential) { context.referential }

      before { referential.switch }

      let(:expected_message) do
        an_object_having_attributes(message_attributes: { 'count' => 2 })
      end

      it 'should clean all vehicle journeys' do
        expect { subject }.to change { referential.vehicle_journeys.count }.from(2).to(0)
        expect(macro_run.macro_messages).to include(expected_message)
      end
    end
  end
end
