
RSpec.describe ApplicationDaysSupport do

  let(:test_class) { Struct.new(:int_day_types) { include ApplicationDaysSupport } }
  subject { test_class.new }

  describe "#applicable_weekday?" do

    it "returns false if weekday is less than 0" do
      expect(subject.applicable_weekday?(-1)).to be_falsy
    end

    it "returns false if weekday is more than 6" do
      expect(subject.applicable_weekday?(7)).to be_falsy
    end

    it "returns true if weekday matchs day_by_mask" do
      expect(subject).to receive(:day_by_mask).with(ApplicationDaysSupport::SUNDAY).and_return true
      expect(subject.applicable_weekday?(0)).to be_truthy
    end

    it "returns false if weekday doesn't match day_by_mask" do
      expect(subject).to receive(:day_by_mask).with(ApplicationDaysSupport::SUNDAY).and_return false
      expect(subject.applicable_weekday?(0)).to be_falsy
    end

  end

  describe "#applicable_date?" do

    let(:date) { Date.today }

    it "returns true if date weeday is applicable_weekday?" do
      expect(subject).to receive(:applicable_weekday?).with(date.wday).and_return(true)
      expect(subject.applicable_date?(date)).to be_truthy
    end

    it "returns false if date weeday isn't applicable_weekday?" do
      expect(subject).to receive(:applicable_weekday?).with(date.wday).and_return(false)
      expect(subject.applicable_date?(date)).to be_falsy
    end

  end

end
