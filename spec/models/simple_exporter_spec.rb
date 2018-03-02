RSpec.describe SimpleExporter do
  describe "#define" do
    context "with an incomplete configuration" do
      it "should raise an error" do
        SimpleExporter.define :foo
        expect do
          SimpleExporter.new(configuration_name: :test).export
        end.to raise_error
      end
    end
    context "with a complete configuration" do
      before do
        SimpleExporter.define :foo do |config|
          config.collection = Chouette::StopArea.all
        end
      end

      it "should define an exporter" do
        expect{SimpleExporter.find_configuration(:foo)}.to_not raise_error
        expect{SimpleExporter.new(configuration_name: :foo, filepath: "").export}.to_not raise_error
        expect{SimpleExporter.find_configuration(:bar)}.to raise_error
        expect{SimpleExporter.new(configuration_name: :bar, filepath: "")}.to_not raise_error
        expect{SimpleExporter.new(configuration_name: :bar, filepath: "").export}.to raise_error
        expect{SimpleExporter.create(configuration_name: :foo, filepath: "")}.to change{SimpleExporter.count}.by 1
      end
    end

    context "when defining the same col twice" do
      it "should raise an error" do
        expect do
          SimpleExporter.define :foo do |config|
            config.collection = Chouette::StopArea.all
            config.add_column :name
            config.add_column :name
          end
        end.to raise_error
      end
    end
  end

  describe "#export" do
    let(:exporter){ importer = SimpleExporter.new(configuration_name: :test, filepath: filepath) }
    let(:filepath){ Rails.root + "tmp/" + filename }
    let(:filename){ "stop_area.csv" }
    # let(:stop_area_referential){ create(:stop_area_referential, objectid_format: :stif_netex) }

    before(:each) do
      @stop_area = create :stop_area
      SimpleExporter.define :test do |config|
        config.collection = ->{ Chouette::StopArea.all }
        config.separator = ";"
        config.add_column :name
        config.add_column :lat, attribute: :latitude
        config.add_column :lng, attribute: :latitude, value: ->(raw){ raw.to_f + 1 }
        config.add_column :type, attribute: :area_type
        config.add_column :street_name, value: "Lil Exporter"
      end
    end

    it "should export the given file" do
      expect{exporter.export verbose: true}.to_not raise_error
      expect(exporter.status).to eq "success"
      expect(File.exists?(filepath)).to be_truthy
      csv = CSV.read(filepath, headers: true, col_sep: ";")
      row = csv.by_row.values_at(0).last
      expect(row["name"]).to eq @stop_area.name
      expect(row["lat"]).to eq @stop_area.latitude.to_s
      expect(row["lng"]).to eq (@stop_area.latitude.to_f + 1).to_s
      expect(row["street_name"]).to eq "Lil Exporter"
    end
  end
end
