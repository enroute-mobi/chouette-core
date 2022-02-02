describe Chouette::TimeTablePeriod, :type => :model do

  let!(:time_table) { create(:time_table, :empty)}
  let!(:new_period) { build(:time_table_period ,:time_table => time_table, :period_start => Date.new(2014,6,30), :period_end => Date.new(2014,7,6) ) }
  # Used only for checksum
  subject { create(:time_table_period ,:time_table => time_table, :period_start => Date.new(2020,6,30), :period_end => Date.new(2020,7,6) ) }

  it { is_expected.to validate_presence_of :period_start }
  it { is_expected.to validate_presence_of :period_end }

  describe 'checksum' do
    it_behaves_like 'checksum support'
  end

  describe "#validate_period_uniqueness" do
    context "when period intersect with other period on the first day, " do
      it "should detect period overlap" do
        create(:time_table_period ,:time_table => time_table, :period_start => Date.new(2014,6,15), :period_end => Date.new(2014,6,30) )
        expect(new_period.valid?).to be_falsey
        expect(new_period.errors[:overlapped_periods]).not_to be_empty
      end
    end

    context "when period intersect with other period on the last day, " do
      it "should detect period overlap" do
        create(:time_table_period ,:time_table => time_table, :period_start => Date.new(2014,7,6), :period_end => Date.new(2014,7,14) )
        expect(new_period.valid?).to be_falsey
        expect(new_period.errors[:overlapped_periods]).not_to be_empty
      end
    end

    context "when period intersect with other period on many days, " do
      it "should detect period overlap" do
        create(:time_table_period ,:time_table => time_table, :period_start => Date.new(2014,7,1), :period_end => Date.new(2014,7,14) )
        expect(new_period.valid?).to be_falsey
        expect(new_period.errors[:overlapped_periods]).not_to be_empty
      end
    end

    context "when period is included in another period, " do
      it "should detect period overlap" do
        create(:time_table_period ,:time_table => time_table, :period_start => Date.new(2014,6,25), :period_end => Date.new(2014,7,8) )
        expect(new_period.valid?).to be_falsey
        expect(new_period.errors[:overlapped_periods]).not_to be_empty
      end
    end

    context "when periods doesn't intersect, " do
      it "should not detect period overlap" do
        create(:time_table_period ,:time_table => time_table, :period_start => Date.new(2014,7,10), :period_end => Date.new(2014,7,12) )
        expect(new_period.valid?).to be_truthy
        expect(new_period.errors[:overlapped_periods]).to be_empty
      end
    end
  end

end
