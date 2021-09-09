RSpec.describe Period do

    describe "during" do
      it "with only Period from date should return a new Period with from and to date calculated from duration" do
        period = Period.new(from: Date.today)
        new_period = period.during(14.days)
        expect(new_period.from).to eq(Date.today)
        expect(new_period.to).to eq(Date.today + 14.days)
      end

      it "with only Period to date should return a new Period with from and to date calculated from duration" do
        period = Period.new(to: Date.today)
        new_period = period.during(14.days)
        expect(new_period.to).to eq(Date.today)
        expect(new_period.from).to eq(Date.today - 14.days)
      end
    end

    describe "valid?" do
      it "should return false if Period#from and Period#to are not defined" do
        period = Period.new()
        expect(period.valid?).to be_falsy
      end

      it "should return false if Period#from is not less or equals to Period#to" do
        period = Period.new(from: Date.today + 1.day, to: Date.today)
        expect(period.valid?).to be_falsy
      end
    end

    describe "empty?" do
      it "should return true if Period#from and Period#to are not defined" do
        period = Period.new()
        expect(period.empty?).to be_truthy
      end

      it "should return false if Period#from or Period#to is not defined" do
        period = Period.new(from: Date.today)
        expect(period.empty?).to be_falsy
      end
    end

    describe "day_count" do
      it "should return a day count if Period#from and Period#to are defined" do
        period = Period.new(from: Date.today, to: Date.today + 14.days)
        expect(period.day_count).to eq(14)
      end

      it "should return a Float::INFINITY if Period#from or/and Period#to is not defined" do
        period = Period.new(from: Date.today)
        expect(period.day_count).to eq(Float::INFINITY)
        period = Period.new()
        expect(period.day_count).to eq(Float::INFINITY)
      end
    end

    describe "time_range" do
      it "should return time range with Period#to +1 day if Period#from and Period#to are defined" do
        period = Period.new(from: Date.today, to: Date.today + 14.days)
        expect(period.time_range).to eq(Date.today.to_datetime..(Date.today+15.days).to_datetime)
      end

      it "should return time range with nil if Period#to is not defined" do
        period = Period.new(from: Date.today)
        expect(period.time_range).to eq(Date.today.to_datetime..nil)
      end
    end

    describe "infinity_time_range" do
      it "should return infinity time range with Period#to +1 day if Period#from and Period#to are defined" do
        period = Period.new(from: Date.today, to: Date.today + 14.days)
        expect(period.infinity_time_range).to eq(Date.today.to_datetime..(Date.today+15.days).to_datetime)
      end

      it "should return time range with Float::INFINITY if Period#to is not defined" do
        period = Period.new(from: Date.today)
        expect(period.infinity_time_range).to eq(Date.today.to_datetime..Float::INFINITY)
      end

      it "should return time range with -Float::INFINITY if Period#from is not defined" do
        period = Period.new(to: Date.today)
        expect(period.infinity_time_range).to eq(-Float::INFINITY..(Date.today+1.day).to_datetime)
      end
    end

    describe "include?" do
      it "should return true if date is included in Period with from and to attribute" do
        period = Period.new(from: Date.today, to: Date.today + 14.days)
        expect(period.include?(Date.today + 2.days)).to be_truthy
      end

      it "should return true if date is after a Period#from attribute" do
        period = Period.new(from: Date.today)
        expect(period.include?(Date.today + 2.days)).to be_truthy
      end

      it "should return true if date is before a Period#to attribute" do
        period = Period.new(to: Date.today)
        expect(period.include?(Date.today - 2.days)).to be_truthy
      end
    end
end
