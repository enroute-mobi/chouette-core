require 'spec_helper'

describe TimeTableCombination, :type => :model do
  let!(:source){ create(:time_table)}
  let!(:combined){create(:time_table)}
  subject {build(:time_table_combination)}

  describe '#continuous_dates' do
    it 'should group continuous dates' do
      dates = source.dates.where(in_out: true)
      expect(source.continuous_dates.flatten.count).to eq(dates.count)

      # 6 more continuous dates, 2 isolated dates
      (10..15).each do |n|
        source.dates.create(date: Date.today + n.day, in_out: true)
      end

      (1..2).each do |n|
         source.dates.create(date: Date.today + n.day + 1.year, in_out: true)
      end

      expect(source.reload.continuous_dates[1].count).to eq(6)
      expect(source.reload.continuous_dates[2].count).to eq(2)
    end
  end

  describe '#convert_continuous_dates_to_periods' do
    it 'should convert continuous dates to periods' do
      source.dates.clear

      (10..12).each do |n|
        source.dates.create(date: Date.today + n.day, in_out: true)
      end

      (1..3).each do |n|
         source.dates.create(date: Date.today + n.day + 1.year, in_out: true)
      end

      expect {
        source.reload.convert_continuous_dates_to_periods
      }.to change {source.periods.count}.by(2)

      expect(source.reload.dates.where(in_out: true).count).to eq(0)
    end
  end

  describe "#combine" do
    context "when operation is union" do
      before(:each) do
        source.periods.clear
        source.dates.clear
        source.int_day_types = 508
        source.periods << Chouette::TimeTablePeriod.new(:period_start => Date.new(2014,8,1), :period_end => Date.new(2014,8,31))
        source.save
        combined.periods.clear
        combined.dates.clear
        combined.int_day_types = 508
        combined.periods << Chouette::TimeTablePeriod.new(:period_start => Date.new(2014,8,15), :period_end => Date.new(2014,9,15))
        combined.save

        subject.operation     = 'union'
        subject.source_id     = source.id
        subject.time_table_id = combined.id
        subject.combined_type = 'time_table'

        subject.combine
        source.reload
      end

      it "should add combined to source" do
        expect(source.periods.size).to eq(1)
        expect(source.periods[0].period_start).to eq(Date.new(2014,8,1))
        expect(source.periods[0].period_end).to eq(Date.new(2014,9,15))
      end
    end
    context "when operation is intersect" do
      before(:each) do
        source.periods.clear
        source.dates.clear
        source.int_day_types = 508
        source.periods << Chouette::TimeTablePeriod.new(:period_start => Date.new(2014,8,1), :period_end => Date.new(2014,8,31))
        source.save
        combined.periods.clear
        combined.dates.clear
        combined.int_day_types = 508
        combined.periods << Chouette::TimeTablePeriod.new(:period_start => Date.new(2014,8,15), :period_end => Date.new(2014,9,15))
        combined.save

        subject.operation     = 'intersection'
        subject.source_id     = source.id
        subject.time_table_id = combined.id
        subject.combined_type = 'time_table'

        subject.combine
        source.reload
      end

      it "should intersect combined to source" do
        expect(source.int_day_types).to eq(508)
        expect(source.periods.size).to eq(1)
  		  expect(source.dates.size).to eq(0)

        expect(source.periods.first.period_start.to_s).to eq('2014-08-15')
        expect(source.periods.first.period_end.to_s).to eq('2014-08-31')
     end
    end

    context "when operation is disjoin" do
      before(:each) do
        source.periods.clear
        source.dates.clear
        source.int_day_types = 508
        source.periods << Chouette::TimeTablePeriod.new(:period_start => Date.new(2014,8,1), :period_end => Date.new(2014,8,31))
        source.save
        combined.periods.clear
        combined.dates.clear
        combined.int_day_types = 508
        combined.periods << Chouette::TimeTablePeriod.new(:period_start => Date.new(2014,8,15), :period_end => Date.new(2014,9,15))
        combined.save

        subject.operation     = 'disjunction'
        subject.source_id     = source.id
        subject.time_table_id = combined.id
        subject.combined_type = 'time_table'

        subject.combine
        source.reload
      end

      it "should disjoin combined to source" do
        expect(source.int_day_types).to eq(508)
        expect(source.periods.size).to eq(1)
		    expect(source.dates.size).to eq(0)

        expect(source.periods.first.period_start.to_s).to eq('2014-08-01')
        expect(source.periods.first.period_end.to_s).to eq('2014-08-14')
      end
    end
 end
end
