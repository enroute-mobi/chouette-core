# frozen_string_literal: true

RSpec.describe TimeTablePresenter do
  subject(:presenter) { TimeTablePresenter.new(time_table) }
  let(:time_table) { Chouette::TimeTable.new int_day_types: ApplicationDaysSupport::EVERYDAY }

  describe '#default_year' do
    subject { presenter.default_year(current) }

    context 'when current date is 2030-06-01' do
      let(:current) { Date.parse '2030-06-01' }

      context "when TimeTable covers '2020-01-01..2020-12-31'" do
        before { time_table.periods.build period_start: Date.parse('2020-01-01'), period_end: Date.parse('2020-12-31') }
        it { is_expected.to eq(2020) }
      end

      context "when TimeTable covers '2040-01-01..2040-12-31'" do
        before { time_table.periods.build period_start: Date.parse('2040-01-01'), period_end: Date.parse('2040-12-31') }
        it { is_expected.to eq(2040) }
      end

      context "when TimeTable covers '2025-01-01..2035-12-31'" do
        before { time_table.periods.build period_start: Date.parse('2025-01-01'), period_end: Date.parse('2035-12-31') }
        it { is_expected.to eq(2030) }
      end
    end
  end
end
