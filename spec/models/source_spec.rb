RSpec.describe Source do

  it "should be a public model (stored into 'public.sources')" do
    expect(Source.table_name).to eq("public.sources")
  end

  let(:source) { Source.new(name: "Source Test", url: "url.com") }

  let(:retrieval) {Source::Retrieval.new(source)}

  context "when source is enabled" do
    it "should perform" do
      expect(source.retrieve).not_to be_empty
    end
  end

  context "when source is enabled" do
    before {source.enabled = false }

    it "should return without creating a Retrieval" do
      expect(source.retrieve).to be_nil
    end
  end

  context "when ignore_checksum is enabled" do
    before {source.ignore_checksum = true }

    it "should return true for checksum_changed?" do
      expect(retrieval.checksum_changed?).to eq(true)
    end
  end
end
