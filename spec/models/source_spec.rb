RSpec.describe Source do

  it "should be a public model (stored into 'public.sources')" do
    expect(Source.table_name).to eq("public.sources")
  end

  let(:workbench) { create(:workbench) }

  let(:source) { Source.create(name: "Source Test", url: "url.com", workbench: workbench) }

  subject { source.retrieve }

  context "when source is not enabled" do
    before {source.enabled = false }

    it "should return without creating a Retrieval" do
      expect(source.retrievals).to be_empty
    end
  end

  context "when ignore_checksum is enabled" do
    let(:retrieval) { source.retrievals.create workbench: workbench, creator: "Source" }

    before { source.update ignore_checksum: true }

    it "should return true for checksum_changed?" do
      expect(retrieval.checksum_changed?).to eq(true)
    end
  end

  context "when the number of records is greater than 20" do
    before do
      30.times do
        source.retrievals.create creator: "Source"
      end
    end

    it "should enqueue the operation and not keep more than 20 retrievals" do
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

RSpec.describe Source::Downloader::URL do

  subject(:downloader) { Source::Downloader::URL.new("http://chouette.test") }

  describe "#download" do

    let(:path) { Tempfile.new.path }

    it "uses a (read) timeout of 120 seconds" do
      expected_options = a_hash_including(read_timeout: 120)
      expect(URI).to receive(:open).
                       with(downloader.url, expected_options).
                       and_return(StringIO.new("dummy"))

      downloader.download(path)
    end
  end
end
