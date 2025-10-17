# frozen_string_literal: true

describe Chouette::TimeTableDate, type: :model do
  subject(:time_table_date) { time_table.dates.first }

  let(:context) do
    Chouette.create do
      referential do
        time_table dates_included: Date.parse('2025-10-20')
      end
    end
  end
  let(:referential) { context.referential }
  let(:time_table) { context.time_table }

  before { referential.switch }

  it { is_expected.to validate_presence_of :date }
  it { is_expected.to validate_uniqueness_of(:date).scoped_to(:time_table_id) }
end
