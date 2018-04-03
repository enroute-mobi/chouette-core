RSpec.describe Chouette::PurchaseWindow, :type => :model do
  let(:referential) {create(:referential)}
  subject  { create(:purchase_window, referential: referential) }

  it { should belong_to(:referential) }
  it { is_expected.to validate_presence_of(:name) }

  describe 'validations' do
    it 'validates and date_ranges do not overlap' do
      expect(build(:purchase_window, referential: referential,date_ranges: [Date.today..Date.today + 10.day, Date.yesterday..Date.tomorrow])).to_not be_valid
      # expect(build(periods: [Date.today..Date.today + 10.day, Date.yesterday..Date.tomorrow ])).to_not be_valid
    end
  end

  describe 'before_validation' do
    let(:purchase_window) { build(:purchase_window, referential: referential, date_ranges: []) }

    it 'shoud fill date_ranges with date ranges' do
      expected_range = Date.today..Date.tomorrow
      purchase_window.date_ranges << expected_range
      purchase_window.valid?

      expect(purchase_window.date_ranges.map { |period| period.begin..period.end }).to eq([expected_range])
    end
  end

  describe "intersect_periods!" do
    let(:date_ranges){[
      (1.month.from_now).to_date..(1.month.from_now+2.day).to_date,
      (2.months.from_now).to_date..(2.months.from_now+2.day).to_date
    ]}
    let(:purchase_window){ create :purchase_window, referential: referential, date_ranges: date_ranges }
    let(:range_bottom){ purchase_window.date_ranges.map(&:first).min }
    let(:range_top){ purchase_window.date_ranges.map(&:last).max }
    context "with an empty mask" do
      let(:mask){ [] }
      it "should do nothing" do
        date_ranges = purchase_window.date_ranges
        purchase_window.intersect_periods! mask
        expect(purchase_window.date_ranges).to eq date_ranges
      end
    end

    context "with an englobbing mask" do
      let(:mask){ [
          (range_bottom..range_top)
        ] }
      it "should do nothing" do
        date_ranges = purchase_window.date_ranges
        purchase_window.intersect_periods! mask
        expect(purchase_window.date_ranges).to eq date_ranges
      end
    end

    context "with a non-overlapping mask" do
      let(:mask){ [
          ((range_top+1.day)..(range_top+2.days))
        ] }
      it "should clear range" do
        purchase_window.intersect_periods! mask
        expect(purchase_window.date_ranges).to eq []
      end
    end

    context "with a partially matching mask" do
      let(:mask){ [
          (1.month.from_now+1.day).to_date..(2.month.from_now + 1.day).to_date,
        ] }
      it "should intersct ranges" do
        purchase_window.intersect_periods! mask
        expect(purchase_window.date_ranges).to eq [
          (1.month.from_now+1.day).to_date..(1.month.from_now+2.day).to_date,
          (2.months.from_now).to_date..(2.months.from_now+1.day).to_date
        ]
      end
    end
  end
end
