RSpec.describe SimpleImporter do
  describe "#define" do
    context "with an incomplete configuration" do

      it "should raise an error" do
        SimpleImporter.define :foo
        expect do
          SimpleImporter.new(configuration_name: :foo, filepath: "").import
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
        expect{SimpleImporter.new(configuration_name: :foo, filepath: "").import}.to_not raise_error
        expect{SimpleImporter.find_configuration(:bar)}.to raise_error
        expect{SimpleImporter.new(configuration_name: :bar, filepath: "")}.to raise_error
        expect{SimpleImporter.create(configuration_name: :foo, filepath: "")}.to change{SimpleImporter.count}.by 1
      end
    end
  end

  describe "#import" do
    let(:importer){ importer = SimpleImporter.new(configuration_name: :test, filepath: filepath) }
    let(:filepath){ fixtures_path 'simple_importer', filename }
    let(:filename){ "stop_area.csv" }
    let(:stop_area_referential){ create(:stop_area_referential, objectid_format: :stif_netex) }

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
        config.add_column :stop_area_referential, value: stop_area_referential
        config.add_value  :kind, :commercial
      end
    end

    it "should import the given file" do
      expect{importer.import verbose: false}.to change{Chouette::StopArea.count}.by 1
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

      context "in another scope" do
        before(:each) do
          ref = create(:stop_area_referential)
          importer.configure do |config|
            config.context = { stop_area_referential: ref }
            config.scope = ->{ context[:stop_area_referential].stop_areas }
          end
        end

        it "should create the record" do
          expect{importer.import verbose: false}.to change{Chouette::StopArea.count}.by 1
          expect(importer.status).to eq "success"
        end
      end
    end

    context "with a missing column" do
      let(:filename){ "stop_area_missing_street_name.csv" }
      it "should set an error message" do
        expect{importer.import(verbose: false)}.to_not raise_error
        expect(importer.status).to eq "success_with_warnings"
        expect(importer.reload.journal.first["event"]).to eq("column_not_found")
      end
    end

    context "with an incomplete dataset" do
      let(:filename){ "stop_area_incomplete.csv" }
      it "should fail" do
        expect{importer.import}.to_not raise_error
        expect(importer.status).to eq "failed"
        expect(importer.reload.journal.last["message"]).to eq({"name" => ["doit être rempli(e)"]})
      end

      it "should be transactional" do
        expect{importer.import}.to_not change {Chouette::StopArea.count}
      end
    end

    context "with a wrong filepath" do
      let(:filename){ "not_found.csv" }
      it "should fail" do
        expect{importer.import}.to_not raise_error
        expect(importer.status).to eq "failed"
        expect(importer.reload.journal.first["message"]).to eq "File not found: #{importer.filepath}"
      end
    end

    context "with a custom behaviour" do
      let!(:present){ create :stop_area, name: "Nom du Stop", stop_area_referential: stop_area_referential }
      let!(:missing){ create :stop_area, name: "Another", stop_area_referential: stop_area_referential }
      before(:each){
        importer.configure do |config|
          config.before do |importer|
            stop_area_referential.stop_areas.each &:deactivate!
          end

          config.before(:each_save) do |importer, stop_area|
            stop_area.activate!
          end
        end
      }

      it "should disable all missing areas" do
        expect{importer.import}.to change{Chouette::StopArea.count}.by 0
        expect(present.reload.activated?).to be_truthy
        expect(missing.reload.activated?).to be_falsy
      end

      context "with an error" do
        let(:filename){ "stop_area_incomplete.csv" }
        it "should do nothing" do
          expect{importer.import}.to_not change {Chouette::StopArea.count}
          expect(present.reload.activated?).to be_truthy
          expect(missing.reload.activated?).to be_truthy
        end
      end
    end

    context "with a full file" do
      let(:filename){ "stop_area_full.csv" }
      let!(:missing){ create :stop_area, name: "Another", stop_area_referential: stop_area_referential }

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
          config.add_value  :stop_area_referential_id, stop_area_referential.id
          config.add_value  :long_lat_type, "WGS84"
          config.add_value  :kind, :commercial
          config.before do |importer|
            stop_area_referential.stop_areas.each &:deactivate!
          end

          config.before(:each_save) do |importer, stop_area|
            stop_area.activate
          end
        end
      end

      it "should import the given file" do
        expect{importer.import(verbose: false)}.to change{Chouette::StopArea.count}.by 2
        expect(importer.status).to eq "success"
        first = Chouette::StopArea.find_by registration_number: "PAR"
        last = Chouette::StopArea.find_by registration_number: "XED"

        expect(last.parent).to eq first
        expect(first.area_type).to eq "gdl"
        expect(last.area_type).to eq "zdep"
        expect(first.long_lat_type).to eq "WGS84"
        expect(first.activated?).to be_truthy
        expect(last.activated?).to be_truthy
        expect(missing.reload.activated?).to be_falsy
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

    context "with a specific importer" do
      let(:filename){ "stop_points_full.csv" }

      before(:each) do
        create :line, name: "Paris <> Londres - OUIBUS"

        SimpleImporter.define :test do |config|
          config.model = Chouette::Route
          config.separator = ";"
          config.context = {stop_area_referential: stop_area_referential}

          config.before do |importer|
            mapping = {}
            path = Rails.root + "spec/fixtures/simple_importer/lines_mapping.csv"
            CSV.foreach(path, importer.configuration.csv_options) do |row|
              if row["Ligne Chouette"].present?
                mapping[row["timetable_route_id"]] ||= Chouette::Line.find_by(name: importer.encode_string(row["Ligne Chouette"]))
              end
            end
            importer.context[:mapping] = mapping
          end

          config.custom_handler do |row|
            line = nil
            fail_with_error "MISSING LINE FOR ROUTE: #{encode_string row["route_name"]}" do
              line = context[:mapping][row["timetable_route_id"]]
              raise unless line
            end
            @current_record = Chouette::Route.find_or_initialize_by number: row["timetable_route_id"]
            @current_record.name = encode_string row["route_name"]
            @current_record.published_name = encode_string row["route_name"]

            @current_record.line = line
            if @prev_route != @current_record
              if @prev_route && @prev_route.valid?
                journey_pattern = @prev_route.full_journey_pattern
                fail_with_error "WRONG DISTANCES FOR ROUTE #{@prev_route.name} (#{@prev_route.number}): #{@distances.count} distances for #{@prev_route.stop_points.count} stops" do
                  journey_pattern.stop_points = @prev_route.stop_points
                  journey_pattern.set_distances @distances
                end
                fail_with_error ->(){ journey_pattern.errors.messages } do
                  journey_pattern.save!
                end
              end
              @distances = []
            end
            @distances.push row["stop_distance"]
            position = row["stop_sequence"].to_i - 1

            stop_area = context[:stop_area_referential].stop_areas.where(registration_number: row["station_code"]).last
            unless stop_area
              stop_area = Chouette::StopArea.new registration_number: row["station_code"]
              stop_area.name = row["station_name"]
              stop_area.kind = row["border"] == "f" ? :commercial : :non_commercial
              stop_area.area_type = row["border"] == "f" ? :zdep : :border
              stop_area.stop_area_referential = context[:stop_area_referential]
              fail_with_error ->{p stop_area; "UNABLE TO CREATE STOP_AREA: #{stop_area.errors.messages}" }, abort_row: true do
                stop_area.save!
              end
            end
            stop_point = @current_record.stop_points.find_by(stop_area_id: stop_area.id)
            if stop_point
              stop_point.set_list_position position
            else
              stop_point = @current_record.stop_points.build(stop_area_id: stop_area.id, position: position)
              stop_point.for_boarding = :normal
              stop_point.for_alighting = :normal
            end

            @prev_route = @current_record
          end

          config.after(:each_save) do |importer, route|
            opposite_route_name = route.name.split(" > ").reverse.join(' > ')
            opposite_route = Chouette::Route.where(name: opposite_route_name).where('id < ?', route.id).last
            if opposite_route && opposite_route.line == route.line
              route.update_attribute :wayback, :inbound
              opposite_route.update_attribute :wayback, :outbound
              route.update_attribute :opposite_route_id, opposite_route.id
              opposite_route.update_attribute :opposite_route_id, route.id
            end
          end

          config.after do |importer|
            prev_route = importer.instance_variable_get "@prev_route"
            if prev_route && prev_route.valid?
              journey_pattern = prev_route.full_journey_pattern
              importer.fail_with_error "WRONG DISTANCES FOR ROUTE #{prev_route.name}: #{importer.instance_variable_get("@distances").count} distances for #{prev_route.stop_points.count} stops" do
                journey_pattern.set_distances importer.instance_variable_get("@distances")
                journey_pattern.stop_points = prev_route.stop_points
              end
              importer.fail_with_error ->(){ journey_pattern.errors.messages } do
                journey_pattern.save!
              end
            end
          end
        end
      end

      it "should import the given file" do
        routes_count = Chouette::Route.count
        journey_pattern_count = Chouette::JourneyPattern.count
        stop_areas_count = Chouette::StopArea.count

        expect{importer.import(verbose: false)}.to change{Chouette::StopPoint.count}.by 10
        expect(importer.status).to eq "success"
        expect(Chouette::Route.count).to eq routes_count + 2
        expect(Chouette::JourneyPattern.count).to eq journey_pattern_count + 2
        expect(Chouette::StopArea.count).to eq stop_areas_count + 5
        route = Chouette::Route.find_by number: 1136
        expect(route.stop_areas.count).to eq 5
        expect(route.opposite_route).to eq Chouette::Route.find_by(number: 1137)
        journey_pattern = route.full_journey_pattern
        expect(journey_pattern.stop_areas.count).to eq 5
        start, stop = journey_pattern.stop_points[0..1]
        expect(journey_pattern.costs_between(start, stop)[:distance]).to eq 232
        start, stop = journey_pattern.stop_points[1..2]
        expect(journey_pattern.costs_between(start, stop)[:distance]).to eq 118
        start, stop = journey_pattern.stop_points[2..3]
        expect(journey_pattern.costs_between(start, stop)[:distance]).to eq 0
        start, stop = journey_pattern.stop_points[3..4]
        expect(journey_pattern.costs_between(start, stop)[:distance]).to eq 177

        route = Chouette::Route.find_by number: 1137
        expect(route.opposite_route).to eq Chouette::Route.find_by(number: 1136)
        expect(route.stop_areas.count).to eq 5
        journey_pattern = route.full_journey_pattern
        expect(journey_pattern.stop_areas.count).to eq 5
        start, stop = journey_pattern.stop_points[0..1]
        expect(journey_pattern.costs_between(start, stop)[:distance]).to eq 177
        start, stop = journey_pattern.stop_points[1..2]
        expect(journey_pattern.costs_between(start, stop)[:distance]).to eq 0
        start, stop = journey_pattern.stop_points[2..3]
        expect(journey_pattern.costs_between(start, stop)[:distance]).to eq 118
        start, stop = journey_pattern.stop_points[3..4]
        expect(journey_pattern.costs_between(start, stop)[:distance]).to eq 232

        stop_area = Chouette::StopArea.where(registration_number: "XPB").last
        expect(stop_area.kind).to eq :commercial
        expect(stop_area.area_type).to eq :zdep

        stop_area = Chouette::StopArea.where(registration_number: "XDB").last
        expect(stop_area.kind).to eq :commercial
        expect(stop_area.area_type).to eq :zdep

        stop_area = Chouette::StopArea.where(registration_number: "COF").last
        expect(stop_area.kind).to eq :non_commercial
        expect(stop_area.area_type).to eq :border

        stop_area = Chouette::StopArea.where(registration_number: "COU").last
        expect(stop_area.kind).to eq :non_commercial
        expect(stop_area.area_type).to eq :border

        stop_area = Chouette::StopArea.where(registration_number: "ZEP").last
        expect(stop_area.kind).to eq :commercial
        expect(stop_area.area_type).to eq :zdep
      end
    end
  end
end
