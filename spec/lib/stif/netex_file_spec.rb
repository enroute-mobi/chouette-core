RSpec.describe Stif::NetexFile do

  let( :zip_file ){ fixtures_path 'OFFRE_TRANSDEV_2017030112251.zip' }

  let(:frames) { described_class.new(zip_file).frames }

  it "should return a frame for each sub directory" do
    expect(frames.size).to eq(2)
  end

  def period(from, to)
    Range.new(Date.parse(from), Date.parse(to))
  end

  context "each frame" do
    it "should return the line identifiers defined in frame" do
      expect(frames.map(&:line_refs).map(&:sort)).to match_array([%w{C00108 C00109}]*2)
    end
    it "should return periods defined in frame calendars" do
      expect(frames.map(&:periods)).to match_array([[period("2017-04-01", "2017-12-31")], [period("2017-03-01","2017-03-31")]])
    end
  end

  context 'with a different namespace' do
    let( :zip_file ){ fixtures_path 'netex_file_different_namespace.zip' }

    context "each frame" do
      it "should return the line identifiers defined in frame" do
        expect(frames.map(&:line_refs).map(&:sort)).to match_array([%w{C00108 C00109}]*2)
      end
      it "should return periods defined in frame calendars" do
        expect(frames.map(&:periods)).to match_array([[period("2017-04-01", "2017-12-31")], [period("2017-03-01","2017-03-31")]])
      end
    end
  end

  context 'without namespace' do
    let( :zip_file ){ fixtures_path 'netex_file_no_namespace.zip' }

    context "each frame" do
      it "should return the line identifiers defined in frame" do
        expect(frames.map(&:line_refs).map(&:sort)).to match_array([%w{C00108 C00109}]*2)
      end
      it "should return periods defined in frame calendars" do
        expect(frames.map(&:periods)).to match_array([[period("2017-04-01", "2017-12-31")], [period("2017-03-01","2017-03-31")]])
      end
    end
  end

  context "calendar parsing" do
    let( :calendar_file_1 ){ fixtures_path "netex-calendar-files/single_period_calendar.xml" }
    let( :calendar_file_2 ){ fixtures_path "netex-calendar-files/multiple_periods_calendar.xml" }

    context "with single period calendar file" do
      let (:periods) do
        Stif::NetexFile::Frame.parse_calendars(File.read(calendar_file_1))
      end

      it "should parse correctly the valid between periods collection" do
        expect(periods).to match_array([period("2017-06-25", "2017-12-31")])
      end
    end

    context "with multiple periods calendar file" do
      let (:periods) do
        Stif::NetexFile::Frame.parse_calendars(File.read(calendar_file_2))
      end

      it "should parse correctly the valid between periods collection" do
        expect(periods).to match_array([
          period("2020-01-02", "2020-04-11"),
          period("2020-04-14","2020-04-30"),
          period("2020-05-02","2020-05-07"),
          period("2020-05-09","2020-05-20"),
          period("2020-05-22","2020-05-30"),
          period("2020-06-02","2020-07-13"),
          period("2020-07-15","2020-08-14"),
          period("2020-08-16","2020-08-30")
        ])
      end
    end
  end
end
