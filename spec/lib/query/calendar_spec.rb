# frozen_string_literal: true

RSpec.describe Query::Calendar do
  subject { query.scope }

  let(:context) do
    Chouette.create do
      workbench do
        calendar :expected, date_ranges: []
        calendar :other, date_ranges: []
      end
    end
  end
  let(:query) { described_class.new(context.workbench.calendars) }
  let(:calendar) { context.calendar(:expected) }

  describe '#text' do
    before { query.text(text) }

    context 'when given text is blank' do
      let(:text) { '' }

      it 'ignores this criteria' do
        is_expected.to match_array(context.workbench.calendars)
      end
    end

    context "when given text is 'Dummy'" do
      let(:text) { 'Dummy' }

      context "when a Calendar is named 'Dummy'" do
        before { calendar.update(name: 'Dummy') }

        it { is_expected.to contain_exactly(calendar) }
      end

      context "when a Calendar is named 'DUMMY'" do
        before { calendar.update(name: 'DUMMY') }

        it { is_expected.to contain_exactly(calendar) }
      end

      context "when a Calendar is named 'Calendar Dummy Sample'" do
        before { calendar.update(name: 'Calendar Dummy Sample') }

        it { is_expected.to contain_exactly(calendar) }
      end
    end
  end

  describe '#shared' do
    before { query.shared(shared) }

    context 'when given value is blank' do
      let(:shared) { nil }

      it 'ignores this criteria' do
        is_expected.to match_array(context.workbench.calendars)
      end
    end

    context 'when given value is true' do
      let(:shared) { true }

      context 'when a Calendar is shared' do
        before { calendar.update(shared: true) }

        it { is_expected.to contain_exactly(calendar) }
      end
    end

    context 'when given value is false' do
      let(:shared) { false }

      context 'when a Calendar is not shared' do
        before { context.calendar(:other).update(shared: true) }

        it { is_expected.to contain_exactly(calendar) }
      end
    end
  end

  describe '#contains_date' do
    before { query.contains_date(date) }

    context 'when given value is blank' do
      let(:date) { nil }

      it 'ignores this criteria' do
        is_expected.to match_array(context.workbench.calendars)
      end
    end

    context 'when given value is a date' do
      let(:date) { Date.new(2025, 8, 4) }

      context 'when a Calendar includes date' do
        before { calendar.update(dates: [Date.new(2025, 8, 4)]) }

        it { is_expected.to contain_exactly(calendar) }
      end

      context 'when a Calendar includes date in a date range' do
        before { calendar.update(date_ranges: [Date.new(2025, 8, 1)..Date.new(2025, 8, 10)]) }

        it { is_expected.to contain_exactly(calendar) }

        context 'when the date is in its excluded dates' do
          before { calendar.update(excluded_dates: [Date.new(2025, 8, 4)]) }

          it { is_expected.to be_empty }
        end
      end
    end
  end
end
