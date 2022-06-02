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

  context "when import options contain processing options" do
    before do
      source.update import_options: source.import_options.
        merge({
          "process_gtfs_route_ids" => ["LR100|20181016", "LR112|20181112"],
          "process_gtfs_ignore_parents" => true
        })
    end

    let(:import_workbench_options) { source.retrievals.last.send(:import_workbench_options) }

    it "should remove all options prefixed by 'process_' beforce create import" do
      subject

      expect(import_workbench_options).not_to match(hash_including("process_gtfs_route_ids", "process_gtfs_ignore_parents"))
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

RSpec.describe Source::Retrieval do
  let(:source) { Source.new }
  subject(:retrieval) { Source::Retrieval.new source: source }

  describe "#import_workbench_options" do
    subject { retrieval.import_workbench_options }

    it "includes Source import_options" do
      source.import_options = { dummy: true }
      is_expected.to include(source.import_options)
    end

    it "exclude Source processing options" do
      source.import_options = { dummy: true, process_option_1: "excluded" }
      is_expected.to_not include("process_option_1" =>  "excluded")
    end

    context "when imported file is an XML file" do
      before { allow(retrieval).to receive(:imported_file_type).and_return(double('xml?' => true)) }
      it { is_expected.to include(import_category: "netex_generic") }
    end
  end

  describe "#processing_options" do
    subject { retrieval.processing_options }

    it "include all import options with a key starting with process_" do
      source.import_options = { not_process_option: "excluded", process_option_1: "included" }.stringify_keys
      is_expected.to include("process_option_1" => "included")
    end
  end

  describe "#imported_file_type" do
    subject { retrieval.imported_file_type }
    context "when imported file is an XML file" do
      before { allow(retrieval).to receive(:imported_file).and_return(open_fixture('reflex.xml')) }
      it { is_expected.to be_xml }
    end

    context "when imported file is an XML file" do
      before { allow(retrieval).to receive(:imported_file).and_return(open_fixture('reflex_updated.zip')) }
      it { is_expected.to be_zip }
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
