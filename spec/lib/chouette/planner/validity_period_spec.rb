RSpec.describe Chouette::Planner::ValidityPeriod do
  def parse(definition)
    return described_class.new if definition == '∞'

    if /(\d{8}):([0-1]+)/ =~ definition
      from = Date.parse Regexp.last_match(1)
      bitset = Bitset.from_s Regexp.last_match(2)

      daysbit = Cuckoo::DaysBit.new from: from, bitset: bitset
      return described_class.from_daysbit daysbit
    end

    raise "Invalid definition '#{definition}'"
  end

  describe '#intersect' do
    subject { period.intersect other }

    [
      ['∞', '∞', '∞'],
      ['20300101:11111', '∞', '20300101:11111'],
      ['∞', '20300101:11111', '20300101:11111'],
      ['20300101:10001', '20300101:11111', '20300101:10001'],
      ['20300101:11111', '20300201:11111', '20300101:00000']
    ].each do |period, other, expected|
      context "with a ValidityPeriod '#{period}' is intersected with '#{other}'" do
        let(:period) { parse period }
        let(:other) { parse other }

        it { is_expected.to eq(parse(expected)) }
      end
    end
  end

  describe '#-' do
    subject { period - other }

    [
      ['∞', '∞', '∞'],
      ['20300101:11111', '∞', '20300101:11111'],
      ['∞', '20300101:11111', '∞'],
      ['20300101:10001', '20300101:10000', '20300101:00001'],
      ['20300101:10001', '20291231:100001', '20300101:10000'],
      ['20300101:11111', '20300101:00100', '20300101:11011'],
      ['20300101:11111', '20300103:1', '20300101:11011'],
      ['20300101:11111', '20300101:11111', '20300101:00000'],
      ['20300101:11111', '20300201:11111', '20300101:11111']
    ].each do |period, other, expected|
      context "a ValidityPeriod '#{period}' - '#{other}'" do
        let(:period) { parse period }
        let(:other) { parse other }

        it { is_expected.to eq(parse(expected)) }
      end
    end
  end
end
