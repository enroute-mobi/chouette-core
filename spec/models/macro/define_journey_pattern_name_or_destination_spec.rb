# frozen_string_literal: true

RSpec.describe Macro::DefineJourneyPatternNameOrDestination do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end
end

RSpec.describe Macro::DefineJourneyPatternNameOrDestination::Run do
  it { should validate_presence_of :target_format }
  it { should validate_presence_of :target_attribute }

  let(:macro_list_run) do
    Macro::List::Run.create workbench: context.workbench, referential: referential
  end

  let(:macro_run) do
    described_class.create(
      macro_list_run: macro_list_run,
      position: 0,
      options: {
        target_format: '%{departure.name} > %{arrival.name}',
        target_attribute: target_attribute
      }
    )
  end

  let(:context) do
    Chouette.create do
      stop_area :first, name: 'Departure'
      stop_area :middle, name: 'Middle'
      stop_area :last, name: 'Arrival'

      referential do
        route stop_areas: %i[first middle last] do
          journey_pattern :journey_pattern
        end
      end
    end
  end

  let(:referential) { context.referential }
  let(:journey_pattern) { context.journey_pattern(:journey_pattern) }
  let(:journey_pattern_name) { journey_pattern.name }
  let(:old_name) { journey_pattern.send(target_attribute) }

  before { referential.switch }

  describe '#run' do
    subject { macro_run.run }

    let(:expected_message) do
      an_object_having_attributes(
        message_attributes: {
          'new_name' => 'Departure > Arrival',
          'journey_pattern_name' => journey_pattern_name
        },
        source: journey_pattern
      )
    end

    context 'with name' do
      let(:target_attribute) { 'name' }

      it 'should update attribute' do
        expect { subject }.to change { journey_pattern.reload.name }.from(old_name).to('Departure > Arrival')
      end

      it 'shoud create message' do
        expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(1)
        expect(macro_run.macro_messages).to include(expected_message)
      end
    end

    context 'with published_name' do
      let(:target_attribute) { 'published_name' }

      it 'should update attribute' do
         expect { subject }.to change { journey_pattern.reload.published_name }.from(old_name).to('Departure > Arrival')
      end

      it 'shoud create message' do
        expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(1)
        expect(macro_run.macro_messages).to include(expected_message)
      end
    end
  end
end
