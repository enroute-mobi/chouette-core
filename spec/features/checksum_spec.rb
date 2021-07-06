RSpec.describe 'Checksum', type: :feature do
  let(:footnote){ create :footnote, code: 1, label: "footnote 1", line: line}

 let(:time_table) do
    tt = create :time_table, {
      int_day_types: 4,
      dates_count: 0,
      periods_count: 0
    }
    create(:time_table_date, time_table: tt, date: "2000/01/01".to_date, in_out: true)
    create(:time_table_period, time_table: tt, period_start: "2000/01/01".to_date, period_end: "2001/01/01".to_date)
    tt.reload
  end

  let(:company){ create :company, id: 1, objectid: "FR:1:ZDE:1:STIF" }

  let(:stop_area_referential) { create :stop_area_referential, objectid_format: 'stif_reflex' }
  let(:stop_area_provider){ create :stop_area_provider, stop_area_referential: stop_area_referential, objectid: "FR:1:ZDE:1:STIF" }

  let(:stop_area_1){
    create :stop_area, id: 1, objectid: "FR:1:ZDE:1:STIF", stop_area_provider: stop_area_provider
  }

  let(:stop_area_2){
    create :stop_area, id: 2, objectid: "FR:1:ZDE:2:STIF", stop_area_provider: stop_area_provider
  }

  let(:stop_area_3){
    create :stop_area, id: 3, objectid: "FR:1:ZDE:3:STIF", stop_area_provider: stop_area_provider
  }

  let(:routing_constraint_zone){
    create(:routing_constraint_zone, route: route, stop_points: route.stop_points[0..1])
  }

  let(:line){
    create(:line, company: company)
  }

  let(:route) do
    stop_area_1 && stop_area_2 && stop_area_3
    r = create :route, {
      name: "name",
      published_name: "published_name",
      wayback: 'inbound',
      stop_points_count: 0,
      line: line
    }
    create :stop_point, stop_area: stop_area_1, route: r, position: 0
    create :stop_point, stop_area: stop_area_2, route: r, position: 1
    create :stop_point, stop_area: stop_area_3, route: r, position: 2
    r.reload
  end

  let(:journey_pattern) do
    create :journey_pattern, {
      name: "name",
      published_name: "published_name",
      registration_number: "registration_number",
      costs: {"1-2": {distance: 12, time: 34}},
      route: route,
      stop_points: route.stop_points
    }
  end

  let(:vehicle_journey) do
    create :vehicle_journey, {
      published_journey_name: "published_journey_name",
      published_journey_identifier: "published_journey_identifier",
      company: company,
      footnotes: [footnote],
      journey_pattern: journey_pattern
    }
  end

  before(:each){
    Chouette::Company.destroy_all
    Chouette::StopArea.destroy_all
    route.routing_constraint_zones = [routing_constraint_zone]
    route.save
  }

  around { |example| Chouette::ChecksumManager.inline{ example.run }}

  context "a Footnote" do
    it "should keep the same checksum" do
      expect(footnote.code).to be_present
      expect(footnote.label).to be_present
      expect(footnote.checksum_source).to eq "1|footnote 1"
      expect(footnote.checksum).to eq "631761e300cee806ceec55fa27462034da4a83ef35525109387811777b49c5ef"
    end
  end

  context "a TimeTable" do
    it "should keep the same checksum" do
      expect(time_table.dates).to be_present
      expect(time_table.periods).to be_present
      expect(time_table.int_day_types).to be_present
      expect(time_table.checksum_source).to eq "4|63390039e754d8b9fb0a9836ee2139421104dcbf880e419c45a06e8991d8ab3b|fe515d93db9a1fd80d7249ee98bb50ece6615fc1e74a2e018b2c1e4770e23b0c"
      expect(time_table.checksum).to eq "e9c70e9c6f1ede9b5431db977e718ad2c9622cf46d3e6a125ce1ccec3edb901f"
    end
  end

  context "a VehicleJourney" do
    it "should keep the same checksum" do
      expect(vehicle_journey.published_journey_name).to be_present
      expect(vehicle_journey.published_journey_identifier).to be_present
      expect(vehicle_journey.company).to be_present
      expect(vehicle_journey.company.get_objectid.local_id.to_s).to eq "1"
      expect(vehicle_journey.footnotes).to be_present
      expect(vehicle_journey.vehicle_journey_at_stops).to be_present
      expect(vehicle_journey.checksum_source).to eq "published_journey_name|published_journey_identifier|1|631761e300cee806ceec55fa27462034da4a83ef35525109387811777b49c5ef|-|46fa73a1d37afcd53d9bb8d8c1f982a632238892be62e4d93019104d69cd40b8,c4f1d8b7656d15667dd3ecf73d1324113fb00b7eeaf63eca0a41e92e4188c413,dcab6bde7033e92dee3afed3ee52691c45334d39cd691705adaf7c92ec9d24d9"
      expect(vehicle_journey.checksum).to eq "1edba1ca2cf3394eb2a11e8391678ad7f5873f6475e5f6d9e00653ba049ae40e"
    end
  end

  context "a VehicleJourneyAtStop" do
    it "should keep the same checksum" do
      vjas = vehicle_journey.vehicle_journey_at_stops.last
      expect(vjas.departure_time).to be_present
      expect(vjas.arrival_time).to be_present
      expect(vjas.departure_day_offset).to be_present
      expect(vjas.arrival_day_offset).to be_present
      expect(vjas.checksum_source).to eq "03:04|03:03|0|0"
      expect(vjas.checksum).to eq "dcab6bde7033e92dee3afed3ee52691c45334d39cd691705adaf7c92ec9d24d9"
    end
  end

  context "a RoutingConstraintZone" do
    it "should keep the same checksum" do
      expect(routing_constraint_zone.stop_points).to be_present
      expect(routing_constraint_zone.stop_points[0].stop_area.local_id.to_s).to eq "1"
      expect(routing_constraint_zone.stop_points[1].stop_area.local_id.to_s).to eq "2"
      expect(routing_constraint_zone.checksum_source).to eq "1,2"
      expect(routing_constraint_zone.checksum).to eq "17f8af97ad4a7f7639a4c9171d5185cbafb85462877a4746c21bdb0a4f940ca0"
    end
  end

  context "a Route" do
    it "should keep the same checksum" do
      expect(route.stop_points).to be_present
      expect(route.stop_points[0].stop_area.local_id.to_s).to eq "1"
      expect(route.stop_points[1].stop_area.local_id.to_s).to eq "2"
      expect(route.stop_points[2].stop_area.local_id.to_s).to eq "3"
      expect(route.routing_constraint_zones).to be_present
      expect(route.name).to be_present
      expect(route.published_name).to be_present
      expect(route.checksum_source).to eq "name|published_name|inbound|(1,normal,normal),(2,normal,normal),(3,normal,normal)|17f8af97ad4a7f7639a4c9171d5185cbafb85462877a4746c21bdb0a4f940ca0"
      expect(route.checksum).to eq "542d947f7763b7417a68107ea8ba6c4e3337f5db0fd911ecc2fda38b55970214"
    end
  end

  context "a JourneyPattern" do
    it "should keep the same checksum" do
      expect(journey_pattern.stop_points).to be_present
      expect(journey_pattern.stop_points.first.stop_area.local_id.to_s).to eq "1"
      expect(journey_pattern.stop_points[1].stop_area.local_id.to_s).to eq "2"
      expect(journey_pattern.stop_points.last.stop_area.local_id.to_s).to eq "3"
      expect(journey_pattern.name).to be_present
      expect(journey_pattern.published_name).to be_present
      expect(journey_pattern.registration_number).to be_present
      expect(journey_pattern.costs).to be_present
      expect(journey_pattern.checksum_source).to eq "name|published_name|registration_number|1|2|3|{\"1-2\"=>{\"distance\"=>12, \"time\"=>34}}"
      expect(journey_pattern.checksum).to eq "21bb57e04b938f18b2f7536bf36422483bbc0ccf7f7163aded727fb0f65dd4a5"
    end
  end
end
