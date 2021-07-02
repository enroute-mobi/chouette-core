require 'range_ext'
RSpec.describe Range do
  describe "#intersection" do
    it "is nil (sic) for two distinct ranges" do
      expect( (1..2).intersection(3..4) ).to be_nil
    end

    it "is the smaller of two if one is part of the other" do
      expect( (1..2).intersection(0..3) ).to eq 1..2
      expect( (0..2).intersection(1..2) ).to eq 1..2
      expect( (2..2).intersection(1..2) ).to eq 2..2
      expect( (1..2).intersection(2..2) ).to eq 2..2
    end

    it "is the intersection otherwise" do
      expect( (1..3) & (2..4) ).to eq 2..3
      expect( (2..4) & (1..3) ).to eq 2..3
    end
  end

  describe "intersect?" do
    it 'is true when the given range includes begin' do
      expect( (2..4).intersect?(1..3) ).to be_truthy
      expect( (2..4).intersect?(2..2) ).to be_truthy
      expect( (2..2).intersect?(2..4) ).to be_truthy
      expect( (2..2).intersect?(2..2) ).to be_truthy
    end

    it 'is true when the given range includes end' do
      expect( (2..4).intersect?(3..5) ).to be_truthy
      expect( (5..5).intersect?(3..5) ).to be_truthy
      expect( (3..5).intersect?(5..5) ).to be_truthy
    end

    it 'is true when the given range includes both begin and end' do
      expect( (2..4).intersect?(1..5) ).to be_truthy
    end

    it 'is true when the given range is the same' do
      expect( (2..4).intersect?(2..4) ).to be_truthy
    end

    it 'is false when the given range is after' do
      expect( (2..4).intersect?(5..7) ).to be_falsey
    end

    it 'is true when the range overlaps on a single value' do
      expect( (2..4).intersect?(4..7) ).to be_truthy
    end

    it 'is false when the given range is before' do
      expect( (3..4).intersect?(0..2) ).to be_falsey
    end
  end

  describe "#remove" do
    it "is unchanged when the given range has no intersection" do
      expect( (1..2).remove(3..4) ).to eq 1..2
      expect( (3..4).remove(1..2) ).to eq 3..4
    end

    it "is an empty array for two equal ranges" do
      expect( (1..2).remove(1..2) ).to be_empty
    end

    it "is the begin of the range when given range intersect the end" do
      expect( (5..10).remove(8..15) ).to eq [5..7]
    end

    it "is the end of the range when given range intersect the begin" do
      expect( (5..10).remove(1..6) ).to eq [7..10]
    end

    it "is the two remaing ranges when given range is the middle" do
      expect( (1..10).remove(4..6) ).to eq [1..3, 7..10]
    end
  end

  describe '.remove' do

    it "removes a complete range if it's included in the removed range" do
      expect( Range.remove [4..5], 2..6 ).to be_empty
    end

    it "returns modified ranges (by #remove method)" do
      expect( Range.remove [1..3,4..5,6..8,100..200], 3..6 ).to eq([1..2, 7..8,100..200])
    end

  end

  describe ".bounds" do

    it "returns the min and max values included in the given ranges" do
      expect(Range.bounds [100..200]).to eq(100..200)
      expect(Range.bounds [1..2,100..200]).to eq(1..200)
      expect(Range.bounds [1..10,15..25,20..30]).to eq(1..30)
    end

    it "returns nil when no range is given" do
      expect(Range.bounds(nil)).to be_nil
      expect(Range.bounds([])).to be_nil
    end

  end

end
