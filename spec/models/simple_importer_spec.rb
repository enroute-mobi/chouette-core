RSpec.describe SimpleImporter do
  describe "#define" do
    context "with an incomplete configuration" do

      it "should raise an error" do
        expect do
          SimpleImporter.define :foo
        end.to raise_error
      end
    end
    context "with a complete configuration" do
      before do
        SimpleImporter.define :foo do |config|
          config.model = "example"
        end
      end

      it "should define an importer" do
        expect{SimpleImporter.find_configuration(:foo)}.to_not raise_error
        expect{SimpleImporter.new(configuration_name: :foo, filepath: "")}.to_not raise_error
        expect{SimpleImporter.find_configuration(:bar)}.to raise_error
        expect{SimpleImporter.new(configuration_name: :bar, filepath: "")}.to raise_error
        expect{SimpleImporter.create(configuration_name: :foo, filepath: "")}.to change{SimpleImporter.count}.by 1
      end
    end
  end

  describe "#import" do
    let(:importer){ importer = SimpleImporter.new(configuration_name: :test, filepath: filepath) }
    let(:filepath){ Rails.root + "spec/fixtures/simple_importer/#{filename}" }
    let(:filename){ "stop_area.csv" }
    before(:each) do
      SimpleImporter.define :test do |config|
        config.model = Chouette::StopArea
        config.separator = ";"
        config.key = "name"
        config.add_column :name
        config.add_column :lat, attribute: :latitude
        config.add_column :lat, attribute: :longitude, value: ->(raw){ raw.to_f + 1 }
        config.add_column :type, attribute: :area_type, value: ->(raw){ raw&.downcase }
        config.add_column :street_name
        config.add_column :stop_area_referential, value: create(:stop_area_referential, objectid_format: :stif_netex)
        config.add_value  :kind, :commercial
      end
    end

    it "should import the given file" do
      expect{importer.import}.to change{Chouette::StopArea.count}.by 1
      expect(importer.status).to eq "success"
      stop = Chouette::StopArea.last
      expect(stop.name).to eq "Nom du Stop"
      expect(stop.latitude).to eq 45.00
      expect(stop.longitude).to eq 46.00
      expect(stop.area_type).to eq "zdep"
      expect(importer.reload.journal.last["event"]).to eq("creation")
    end

    context "when overriding configuration" do
      before(:each){
        importer.configure do |config|
          config.add_value :latitude, 88
        end
      }

      it "should import the given file and not mess with the global configuration" do
        expect{importer.import}.to change{Chouette::StopArea.count}.by 1
        expect(importer.status).to eq "success"
        stop = Chouette::StopArea.last
        expect(stop.latitude).to eq 88
        importer = SimpleImporter.new(configuration_name: :test, filepath: filepath)
        expect{importer.import}.to change{Chouette::StopArea.count}.by 0
        expect(stop.reload.latitude).to eq 45
      end
    end

    context "with an already existing record" do
      let(:filename){ "stop_area.csv" }
      before(:each){
        create :stop_area, name: "Nom du Stop"
      }
      it "should only update the record" do
        expect{importer.import}.to change{Chouette::StopArea.count}.by 0
        expect(importer.status).to eq "success"
        stop = Chouette::StopArea.last
        expect(stop.name).to eq "Nom du Stop"
        expect(stop.latitude).to eq 45.00
        expect(stop.longitude).to eq 46.00
        expect(stop.area_type).to eq "zdep"
        expect(importer.reload.journal.last["event"]).to eq("update")
      end
    end

    context "with a missing column" do
      let(:filename){ "stop_area_missing_street_name.csv" }
      it "should set an error message" do
        expect{importer.import}.to_not raise_error
        expect(importer.status).to eq "success_with_warnings"
        expect(importer.reload.journal.first["event"]).to eq("column_not_found")
      end
    end

    context "with a incomplete dataset" do
      let(:filename){ "stop_area_incomplete.csv" }
      it "should create a StopArea" do
        expect{importer.import}.to_not raise_error
        expect(importer.status).to eq "failed"
        expect(importer.reload.journal.first["message"]).to eq({"name" => ["doit être rempli(e)"]})
      end
    end

    context "with a wrong filepath" do
      let(:filename){ "not_found.csv" }
      it "should create a StopArea" do
        expect{importer.import}.to_not raise_error
        expect(importer.status).to eq "failed"
        expect(importer.reload.journal.first["message"]).to eq "File not found: #{importer.filepath}"
      end
    end

    context "with a full file" do
      let(:filename){ "stop_area_full.csv" }
      before(:each) do
        SimpleImporter.define :test do |config|
          config.model = Chouette::StopArea
          config.separator = ";"
          config.key = "station_code"
          config.add_column :station_code, attribute: :registration_number
          config.add_column :country_code
          config.add_column :station_name, attribute: :name
          config.add_column :inactive, attribute: :deleted_at, value: ->(raw){ raw == "t" ? Time.now : nil }
          config.add_column :change_timestamp, attribute: :updated_at
          config.add_column :longitude
          config.add_column :latitude
          config.add_column :parent_station_code, attribute: :parent, value: ->(raw){ raw.present? && resolve(:station_code, raw){|value| Chouette::StopArea.find_by(registration_number: value) } }
          config.add_column :parent_station_code, attribute: :area_type, value: ->(raw){ raw.present? ? "zdep" : "gdl" }
          config.add_column :timezone, attribute: :time_zone
          config.add_column :address, attribute: :street_name
          config.add_column :postal_code, attribute: :zip_code
          config.add_column :city, attribute: :city_name
          config.add_value  :stop_area_referential_id, create(:stop_area_referential, objectid_format: :stif_netex).id
          config.add_value  :long_lat_type, "WGS84"
          config.add_value  :kind, :commercial
        end
      end

      it "should import the given file" do
        expect{importer.import}.to change{Chouette::StopArea.count}.by 2
        expect(importer.status).to eq "success"
        first = Chouette::StopArea.find_by registration_number: "PAR"
        last = Chouette::StopArea.find_by registration_number: "XED"

        expect(last.parent).to eq first
        expect(first.area_type).to eq "gdl"
        expect(last.area_type).to eq "zdep"
        expect(first.long_lat_type).to eq "WGS84"
      end

      context "with a relation in reverse order" do
        let(:filename){ "stop_area_full_reverse.csv" }

        it "should import the given file" do
          expect{importer.import}.to change{Chouette::StopArea.count}.by 2
          expect(importer.status).to eq "success"
          first = Chouette::StopArea.find_by registration_number: "XED"
          last = Chouette::StopArea.find_by registration_number: "PAR"
          expect(first.parent).to eq last
        end
      end
    end
  end
end
