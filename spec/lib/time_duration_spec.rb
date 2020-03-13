
describe TimeDuration do
  describe ".exceeds_gap?" do
    context "when duration is 4.hours" do
      it "should return false if gap < 1.hour" do
        earlier = Time.now
        later = Time.now + 3.minutes

        expect(TimeDuration.exceeds_gap?(4.hours, earlier, later)).to be false
      end

      it "should return true if gap > 4.hour" do
        earlier = Time.now
        later = Time.now + (4.hours + 1.minutes)

        expect(TimeDuration.exceeds_gap?(4.hours, earlier, later)).to be true
      end

      it "returns true when `earlier` is later than `later`" do
        earlier = Time.new(2000, 1, 1, 11, 0, 0, 0)
        later = Time.new(2000, 1, 1, 12, 0, 0, 0)

        expect(TimeDuration.exceeds_gap?(4.hours, later, earlier)).to be true
      end

      it "returns false when `earlier` == `later`" do
        earlier = Time.new(2000, 1, 1, 1, 0, 0, 0)
        later = earlier

        expect(TimeDuration.exceeds_gap?(4.hours, later, earlier)).to be false
      end
    end
  end
end
