describe Chouette::TimeTablePeriod, :type => :model do

  subject { Chouette::TimeTablePeriod.new }

  it { is_expected.to validate_presence_of :period_start }
  it { is_expected.to validate_presence_of :period_end }

  describe "#validate_period_uniqueness" do

    let(:context) { Chouette.create { time_table } }
    before { context.referential.switch }

    let(:time_table) { context.time_table }
    subject(:period) { time_table.periods.build period_start: Date.new(2014,6,30), period_end: Date.new(2014,7,6) }

    context "when another period intersects on the first day" do
      before { time_table.periods.create period_start: Date.new(2014,6,15), period_end: Date.new(2014,6,30) }

      it { is_expected.to_not be_valid }

      describe "#errors" do
        subject { period.errors }
        before { period.validate_period_uniqueness }
        it { is_expected.to have_key(:overlapped_periods) }
      end
    end

    context "when another period intersects on the last day" do
      before { time_table.periods.create period_start: Date.new(2014,7,6), period_end: Date.new(2014,7,14) }

      it { is_expected.to_not be_valid }

      describe "#errors" do
        subject { period.errors }
        before { period.validate_period_uniqueness }
        it { is_expected.to have_key(:overlapped_periods) }
      end
    end

    context "when another period intersects on many days" do
      before { time_table.periods.create period_start: Date.new(2014,7,1), period_end: Date.new(2014,7,14) }

      it { is_expected.to_not be_valid }

      describe "#errors" do
        subject { period.errors }
        before { period.validate_period_uniqueness }
        it { is_expected.to have_key(:overlapped_periods) }
      end
    end

    context "when another period overlappeds" do
      before { time_table.periods.create period_start: Date.new(2014,6,25), period_end: Date.new(2014,7,8) }

      it { is_expected.to_not be_valid }

      describe "#errors" do
        subject { period.errors }
        before { period.validate_period_uniqueness }
        it { is_expected.to have_key(:overlapped_periods) }
      end
    end

    context "when no period intersects" do
      before { time_table.periods.create period_start: Date.new(2014,7,10), period_end: Date.new(2014,7,12) }

      it { is_expected.to be_valid }
    end
  end

  describe ".transform_in_dates" do
    subject { time_table.periods.transform_in_dates }

    let(:context) { Chouette.create { time_table :time_table, periods: [] } }
    before { context.referential.switch }

    let(:time_table) { context.instance(:time_table) }

    context "when a Period covers a single day" do
      before { time_table.periods.build(range: Period.from(:today).during(1.day)).save(validate: false) }

      it { expect { subject }.to change { time_table.reload.periods.count }.from(1).to(0) }
      it { expect { subject }.to change { time_table.reload.dates.count }.from(0).to(1) }

      describe "described Date" do
        subject(:date) { time_table.reload.dates.first }

        before { time_table.periods.transform_in_dates }

        it "covers the Period day" do
          is_expected.to have_attributes(date: Time.zone.today)
        end
      end
    end
  end

end
