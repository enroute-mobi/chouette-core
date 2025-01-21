
RSpec.describe GtfsTime do

  it "returns an UTC Time with given H:M:S" do
    expect(GtfsTime.parse("14:29:00").time).to eq(Time.parse("2000-01-01 14:29:00 +00"))
  end

  it "supports hours with a single digit" do
    expect(GtfsTime.parse("4:29:00").time).to eq(Time.parse("2000-01-01 04:29:00 +00"))
  end

  it "supports minutes with a single digit" do
    expect(GtfsTime.parse("14:0:00").time).to eq(Time.parse("2000-01-01 14:00:00 +00"))
  end

  it "supports seconds with a single digit" do
    expect(GtfsTime.parse("14:00:0").time).to eq(Time.parse("2000-01-01 14:00:00 +00"))
  end

  it "return nil for invalid format" do
    expect(GtfsTime.parse("abc")).to be_nil
  end

  it "removes 24 hours after 23:59:59" do
    expect(GtfsTime.parse("25:29:00").time).to eq(Time.parse("2000-01-01 01:29:00 +00"))
  end

  it "returns a day_offset for each 24 hours turn" do
    expect(GtfsTime.parse("10:00:00").day_offset).to eq(0)
    expect(GtfsTime.parse("30:00:00").day_offset).to eq(1)
    expect(GtfsTime.parse("50:00:00").day_offset).to eq(2)
  end

  it "handles time zone" do
    expect(GtfsTime.parse("13:00:00").time("Europe/Paris")).to eq(Time.parse("2000-01-01 12:00:00 +00"))
    expect(GtfsTime.parse("25:00:00").time("Europe/Sofia")).to eq(Time.parse("2000-01-01 23:00:00 +00"))
    expect(GtfsTime.parse("27:00:00").time("Europe/Sofia")).to eq(Time.parse("2000-01-01 01:00:00 +00"))
  end

  it "formats datetime with 2 digits" do
    expect(GtfsTime.format_datetime(Time.parse("2000-01-01 04:00:00 +00"), 0)).to eq "04:00:00"
  end

  it "format datetime by correctly handling time zones" do
    expect(GtfsTime.format_datetime(Time.parse("2000-01-01 12:00:00 +00"), 0, "Europe/Paris")).to eq "13:00:00"
    expect(GtfsTime.format_datetime(Time.parse("2000-01-01 23:30:00 +00"), 0, "Europe/Paris")).to eq "24:30:00"
  end
end
