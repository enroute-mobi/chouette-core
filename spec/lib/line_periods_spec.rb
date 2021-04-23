RSpec.describe LinePeriods do

  def line_periods(definition = {})
    LinePeriods.new.tap do |line_periods|
      definition.each do |line_id, periods|
        periods.each do |period|
          line_periods.add line_id, period
        end
      end
    end
  end

  describe "#==" do

    context "when the two LinePeriods define the same periods for each line identifier" do

      it "they are equal" do
        [
          line_periods(first: ["2030-01-01".."2030-01-31"]),
          line_periods(first: ["2030-01-01".."2030-01-31"], second: ["2031-01-01", "2031-01-31"]),
          line_periods(first: ["2030-01-01".."2030-01-31", "2031-01-01".."2031-01-31"])
        ].each do |line_period|
          expect(line_period).to eq(line_period.dup)
        end
      end

    end

    context "when the two LinePeriods doesn't define exactly the same periods for each line identifier" do

      it "they are not equal" do
        [
          [ line_periods(first: ["2030-01-01".."2030-01-31"]),
            line_periods(first: ["2031-01-01".."2031-01-31"])],
          [ line_periods(first: ["2030-01-01".."2030-01-31"], second: ["2030-01-01", "2030-01-31"]),
            line_periods(first: ["2030-01-01".."2030-01-31"], second: ["2031-01-01", "2031-01-31"])],
          [ line_periods(first: ["2030-01-01".."2030-01-31", "2031-01-01".."2031-01-31"]),
            line_periods(first: ["2030-01-01".."2030-01-31", "2032-01-01".."2032-01-31"])]
        ].each do |line_period, other|
          expect(line_period).to_not eq(other)
        end
      end

    end

  end

end
