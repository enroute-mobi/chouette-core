RSpec.describe Export::GTFS, type: :model do
  describe ".export_companies_to target" do
    it "should xxx" do
      # instancier exporter

      tmp_dir = Dir.mktmpdir
      zip_path = File.join(tmp_dir, '/test.zip')

      GTFS::Target.open(zip_path) do |target|
        exporter.export_companies_to target
      end

      source = GTFS::Source.build(zip_path)

      # source.agencies.length.should eq(2)
    end
  end
end