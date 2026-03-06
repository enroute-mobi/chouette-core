# frozen_string_literal: true

RSpec.describe LegacyObjectidLoaderInserter do
  subject(:inserter) { LegacyObjectidLoaderInserter.new(referential) }

  let(:referential) { Referential.new(id: 42, prefix: 'test') }

  let(:model) { Chouette::Route.new }

  let(:line) { Chouette::Line.new(id: 123, objectid: 'test:Line:dummy:LOC') }
  let(:route) { Chouette::Route.new(line: line) }

  describe 'insert' do
    subject { inserter.insert model }

    context 'when referential prefix is 42' do
      it { is_expected_to change { model.transient(:referential_id) }.from(nil).to(42) }
    end

    context 'when referential prefix is "test"' do
      it { is_expected_to change { model.transient(:referential_prefix) }.from(nil).to('test') }
    end

    context 'when model is associated to a line' do
      let(:model) { route }

      it { is_expected_to change { model.transient(:line_code) }.from(nil).to('dummy') }
    end

    context 'when model is associated to a route (a StopPoint for example)' do
      let(:model) { Chouette::StopPoint.new(route: route) }

      it { is_expected_to change { model.transient(:line_code) }.from(nil).to('dummy') }
    end

    context "when model isn't associated to a route or a line (a Timetable for example)" do
      let(:model) { Chouette::TimeTable.new }

      it { is_expected_to_not change { model.transient(:line_code) }.from(nil) }
    end
  end
end
