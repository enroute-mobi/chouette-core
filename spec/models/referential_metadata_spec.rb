# frozen_string_literal: true

RSpec.describe ReferentialMetadata, :type => :model do

  it { is_expected.to belong_to(:referential).required }
  it { is_expected.to belong_to(:referential_source).optional }

  context '', pending: 'validate_presence_of does not support has_array_of (= nil)' do # TODO: CHOUETTE-2397
    it { is_expected.to validate_presence_of(:lines) }
  end
  it { is_expected.to validate_presence_of(:periodes) }

  describe ".new_from" do
    let(:line_referential){ create :line_referential }
    let(:workbench){ create :workbench, line_referential: line_referential}
    let(:referential){ create :workbench_referential, workbench: workbench, line_referential: line_referential }
    let(:referential_metadata) { create :referential_metadata, referential: referential }
    let(:new_referential_metadata) { ReferentialMetadata.new_from(referential_metadata, referential.workbench) }
    before do
      allow(Workgroup).to receive(:workbench_scopes_class).and_return(WorkbenchScopes::All)
      referential_metadata.line_ids.each do |id|
        Chouette::Line.find(id).update_attribute :line_referential_id, line_referential.id
      end
    end

    it "should not have an associated referential" do
      expect(new_referential_metadata).to be_a_new(ReferentialMetadata)
    end

    it "should have the same lines" do
      expect(new_referential_metadata.line_ids.sort).to eq(referential_metadata.line_ids.sort)
    end

    it "should have the same periods" do
      expect(new_referential_metadata.periodes).to eq(referential_metadata.periodes)
    end

    it "should not have an associated referential" do
      expect(new_referential_metadata.referential).to be(nil)
    end

    it "should have the same referential source" do
      expect(new_referential_metadata.referential_source).to eq(referential_metadata.referential_source)
    end
  end

  describe "Period" do

    subject { period }

    def period(attributes = {})
      return @period if attributes.empty? and @period
      ReferentialMetadata::Period.new(attributes).tap do |period|
        @period = period if attributes.empty?
      end
    end

    it "should support mark_for_destruction (required by cocoon)" do
      period.mark_for_destruction
      expect(period).to be_marked_for_destruction
    end

    it "should support _destroy attribute (required by coocon)" do
      period._destroy = true
      expect(period).to be_marked_for_destruction
    end

    it "should support new_record? (required by cocoon)" do
      expect(ReferentialMetadata::Period.new).to be_new_record
      expect(period(id: 42)).not_to be_new_record
    end

    it "should cast begin as date attribute" do
      expect(period(begin: "2016-11-22").begin).to eq(Date.new(2016,11,22))
    end

    it "should cast end as date attribute" do
      expect(period(end: "2016-11-22").end).to eq(Date.new(2016,11,22))
    end

    it "should support multiparameter on begin attribute" do
      expect(period("begin(3i)"=>"18", "begin(2i)"=>"2", "begin(1i)"=>"2017").begin).to eq(Date.new(2017,2,18))
    end

    it "should support multiparameter on end attribute" do
      expect(period("end(3i)"=>"18", "end(2i)"=>"2", "end(1i)"=>"2017").end).to eq(Date.new(2017,2,18))
    end

    it "should ignore invalid date" do
      expect(period("end(3i)"=>"30", "end(2i)"=>"2", "end(1i)"=>"2017").end).to eq(nil)
    end

    it { is_expected.to validate_presence_of(:begin) }
    it { is_expected.to validate_presence_of(:end) }

    it "should validate that end is greather than or equlals to begin" do
      expect(period(begin: "2016-11-21", end: "2016-11-22")).to be_valid
      expect(period(begin: "2016-11-21", end: "2016-11-21")).to be_valid
      expect(period(begin: "2016-11-22", end: "2016-11-21")).to_not be_valid
    end

    describe "intersect?" do

      it "should detect date in common with other periods" do
        november = period(begin: "2016-11-01", end: "2016-11-30")
        mid_november_mid_december = period(begin: "2016-11-15", end: "2016-12-15")
        expect(november.intersect?(mid_november_mid_december)).to be(true)
      end

      it "should not intersect when no date is in common" do
        november = period(begin: "2016-11-01", end: "2016-11-30")
        december = period(begin: "2016-12-01", end: "2016-12-31")

        expect(november.intersect?(december)).to be(false)

        january = period(begin: "2017-01-01", end: "2017-01-31")
        expect(november.intersect?(december, january)).to be(false)
      end

      it "should not intersect itself" do
        period = period(id: 42, begin: "2016-11-01", end: "2016-11-30")
        expect(period.intersect?(period)).to be(false)
      end

    end

  end

  describe "#periodes" do
    let(:referential_metadata) { create(:referential_metadata).reload }

    it "should not exclude end" do
      expect(referential_metadata.periodes).to_not be_empty
      referential_metadata.periodes.each do |periode|
        expect(periode).to_not be_exclude_end
      end
    end
  end

  describe "#adapted_periods" do
    let(:referential_metadata) { create(:referential_metadata).reload }

    it "should not exclude end" do
      period = (Time.now.to_date..1.month.from_now.to_date)
      expect(referential_metadata.send(:adapted_periods, [period]).first).to eq period
      exclude_end_period = (Time.now.to_date...(1.month.from_now + 1.day).to_date)
      expect(referential_metadata.send(:adapted_periods, [exclude_end_period]).first).to eq period
    end
  end

  describe "before_validation" do
    let(:referential_metadata) do
      create(:referential_metadata).tap do |metadata|
        metadata.periodes = []
      end
    end

    it "shoud fill periodes with period ranges" do
      expected_ranges = [
        Range.new(Date.today, Date.tomorrow)
      ]
      expected_ranges.each_with_index do |range, index|
        referential_metadata.periods << ReferentialMetadata::Period.from_range(index, range)
      end
      referential_metadata.valid?

      expect(referential_metadata.periodes).to eq(expected_ranges)
    end
  end

  describe ".includes_lines" do

    let(:referential_metadata) { create :referential_metadata }

    it "should find ReferentialMetadata associated with given Line" do
      expect(ReferentialMetadata.include_lines(referential_metadata.lines)).to eq([referential_metadata])
    end

  end

  describe ".include_daterange" do

    let(:context) do
      Chouette.create do
        referential periods: [ Date.parse("2030-06-01")..Date.parse("2030-06-30") ]
      end
    end

    let(:referential) { context.referential }
    let(:metadata) { referential.metadatas.first }

    let(:metadata_begin) { metadata.periods.first.begin }
    let(:metadata_end) { metadata.periods.first.end }

    subject { referential.metadatas.include_daterange(date_range) }

    context "when date range is before any metadata" do
      let(:date_range) { metadata_begin-100..metadata_begin-10 }
      it { is_expected.to be_empty }
    end

    context "when date range is after any metadata" do
      let(:date_range) { metadata_end+1..metadata_end+100 }
      it { is_expected.to be_empty }
    end

    matcher :find_the_metadata do
      match { |actual| actual.include? metadata }
    end

    context "when the date range ends into one the metadata periods" do
      let(:date_range) { metadata_begin-10..metadata_begin }
      it { is_expected.to find_the_metadata }
    end

    context "when the date range begins into the metadata period" do
      let(:date_range) { metadata_end..metadata_end+10 }
      it { is_expected.to find_the_metadata }
    end

    context "when the date range is the same range than the metadata period" do
      let(:date_range) { metadata_begin..metadata_end }
      it { is_expected.to find_the_metadata }
    end

    context "when the date range is into the metadata period" do
      let(:date_range) { metadata_begin+1..metadata_end-1 }
      it { is_expected.to find_the_metadata }
    end

  end

  describe ".start_before" do

    let(:context) do
      Chouette.create do
        referential periods: [ Date.parse("2030-06-01")..Date.parse("2030-06-14"),
                               Date.parse("2030-06-15")..Date.parse("2030-06-30") ]
      end
    end

    let(:referential) { context.referential }
    let(:metadata) { referential.metadatas.first }
    subject { referential.metadatas.start_before(date) }

    context "when the metadata period is 2030-06-01..2030-06-30" do

      context "when the given date is 2030-07-01" do
        let(:date) { Date.parse '2030-07-01' }
        it "includes the metadata" do
          is_expected.to include(metadata)
        end
      end

      context "when the given date is 2030-06-30" do
        let(:date) { Date.parse '2030-06-30' }
        it "includes the metadata" do
          is_expected.to include(metadata)
        end
      end

      context "when the given date is 2030-06-02" do
        let(:date) { Date.parse '2030-06-02' }
        it "includes the metadata" do
          is_expected.to include(metadata)
        end
      end

      context "when the given date is 2030-06-01" do
        let(:date) { Date.parse '2030-06-01' }
        it "doesn't include the metadata" do
          is_expected.to_not include(metadata)
        end
      end

      context "when the given date is 2030-05-31" do
        let(:date) { Date.parse '2030-05-31' }
        it "doesn't include the metadata" do
          is_expected.to_not include(metadata)
        end
      end

    end

  end

end
