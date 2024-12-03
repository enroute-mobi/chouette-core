# frozen_string_literal: true

RSpec.describe Chouette::Planner::Extender::WalkableStopAreas do
  subject(:extender) { described_class.new stop_areas }

  let(:position) { '48.858333,2.294444' } # Eiffel Tower

  let(:context) do
    Chouette.create do
      stop_area position: Geo::Position.parse('48.858333,2.294444').around(distance: 499)
    end
  end

  let(:stop_area) { context.stop_area }
  let(:stop_areas) { Chouette::StopArea.where(id: stop_area) }

  describe '#extend' do
    let(:last_step) { Chouette::Planner::Step.for(position) }
    let(:journey) { Chouette::Planner::Journey.new(step: last_step) }

    subject(:extended_journeys) { extender.extend [journey] }

    it { should have_attributes(size: 1) }

    context 'extended journey' do
      subject(:extended_journey) { extended_journeys.first }

      it { is_expected.to have_attributes(last: an_object_having_attributes(stop_area_id: stop_area.id)) }
    end
  end
end
