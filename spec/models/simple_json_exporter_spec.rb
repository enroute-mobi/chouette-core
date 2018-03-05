RSpec.describe SimpleJsonExporter do
  describe "#define" do
    context "with an incomplete configuration" do
      it "should raise an error" do
        SimpleJsonExporter.define :foo
        expect do
          SimpleJsonExporter.new(configuration_name: :test).export
        end.to raise_error
      end
    end
    context "with a complete configuration" do
      before do
        SimpleJsonExporter.define :foo do |config|
          config.collection = Chouette::StopArea.all
        end
      end

      it "should define an exporter" do
        expect{SimpleJsonExporter.find_configuration(:foo)}.to_not raise_error
        expect{SimpleJsonExporter.new(configuration_name: :foo, filepath: "").export}.to_not raise_error
        expect{SimpleJsonExporter.find_configuration(:bar)}.to raise_error
        expect{SimpleJsonExporter.new(configuration_name: :bar, filepath: "")}.to raise_error
        expect{SimpleJsonExporter.new(configuration_name: :bar, filepath: "").export}.to raise_error
        expect{SimpleJsonExporter.create(configuration_name: :foo, filepath: "")}.to change{SimpleJsonExporter.count}.by 1
      end
    end

    context "when defining the same col twice" do
      it "should raise an error" do
        expect do
          SimpleJsonExporter.define :foo do |config|
            config.collection = Chouette::StopArea.all
            config.add_field :name
            config.add_field :name
          end
        end.to raise_error
      end
    end
  end

  describe "#export" do
    let(:exporter){ importer = SimpleJsonExporter.new(configuration_name: :test, filepath: filepath) }
    let(:filepath){ Rails.root + "tmp/" + filename }
    let(:filename){ "stop_area.json" }
    # let(:stop_area_referential){ create(:stop_area_referential, objectid_format: :stif_netex) }

    context "with one row per item" do
      before(:each) do
        @stop_area = create :stop_area
        @stop_1 = create :stop_point, stop_area: @stop_area
        @stop_2 = create :stop_point, stop_area: @stop_area

        SimpleJsonExporter.define :test do |config|
          config.collection = ->{ Chouette::StopArea.all }
          config.root = "stops"
          config.add_field :name
          config.add_field :lat, attribute: :latitude
          config.add_field :lng, attribute: [:latitude, :to_i, :next]
          config.add_field :type, attribute: :area_type
          config.add_field :street_name, value: "Lil Exporter"
          config.add_node :stop_area_referential do |config|
            config.add_field :id, attribute: :id
            config.add_field :id_other, value: ->(item){ item.id }
          end

          config.add_nodes :stop_points do |config|
            config.add_field :id
            config.add_node :stop_area do |config|
              config.add_field :id
            end
          end
          config.add_field :forty_two, value: 42
        end
      end

      it "should export the given file" do
        expect{exporter.export verbose: false}.to_not raise_error
        expect(exporter.status).to eq "success"
        expect(File.exists?(filepath)).to be_truthy
        json = JSON.parse File.read(filepath)
        row = json["stops"].first
        expect(row["name"]).to eq @stop_area.name
        expect(row["lat"]).to eq @stop_area.latitude.to_s
        expect(row["lng"]).to eq (@stop_area.latitude.to_i + 1)
        expect(row["street_name"]).to eq "Lil Exporter"
        expect(row["stop_area_referential"]["id"]).to eq @stop_area.stop_area_referential_id
        expect(row["stop_area_referential"]["id_other"]).to eq @stop_area.stop_area_referential_id
        expect(row["stop_points"][0]["id"]).to eq @stop_1.id
        expect(row["stop_points"][0]["stop_area"]["id"]).to eq @stop_area.id
        expect(row["stop_points"][1]["id"]).to eq @stop_2.id
        expect(row["forty_two"]).to eq 42
      end
    end
  end
end
