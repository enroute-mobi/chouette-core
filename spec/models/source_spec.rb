RSpec.describe Source do

  it "should be a public model (stored into 'public.sources')" do
    expect(Source.table_name).to eq("public.sources")
  end

  let(:workbench) { create(:workbench) }

  let(:source) { Source.create(name: "Source Test", url: "url.com", workbench: workbench) }

  let(:retrieval) {Source::Retrieval.create!({source: source, workbench: workbench, creator: "Source"})}

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

  context "when the number of records is greater than 20" do
    let(:source) { Source.create(name: "Source Test", url: "url.com", workbench: workbench) }

    before do
      30.times do
        Source::Retrieval.create!({source: source, workbench: workbench, creator: "Source"})
      end
    end

    subject { source.retrieve }

    it "should perform and not keep more than 20 retrievals" do
      expect { subject }.to change { source.retrievals.count }.from(30).to(20)
    end
  end

  describe "#downloader_class" do
    subject { source.downloader_class }
    context "when downloader_type is nil" do
      before { source.downloader_type = nil }
      it { is_expected.to eq(Source::Downloader::URL) }
    end
    context "when downloader_type is :direct" do
      before { source.downloader_type = :direct }
      it { is_expected.to eq(Source::Downloader::URL) }
    end
    context "when downloader_type is :french_nap" do
      before { source.downloader_type = :french_nap }
      it { is_expected.to eq(Source::Downloader::FrenchNap) }
    end
  end
end
