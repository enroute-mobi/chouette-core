# frozen_string_literal: true

RSpec.describe Chouette::VehicleJourney do
  describe '.scheduled_on' do
    subject { referential.vehicle_journeys.scheduled_on(date) }
    before { referential.switch }

    let(:context) do
      Chouette.create do
        time_table :first
        time_table :second
        vehicle_journey time_tables: %i[first second]
      end
    end
    let(:referential) { context.referential }
    let(:vehicle_journey) { context.vehicle_journey }

    let(:date) { double }

    context 'when no TimeTable is schedule on the given date' do
      before { allow(Chouette::TimeTable).to receive(:scheduled_on).and_return(Chouette::TimeTable.none) }

      it { is_expected.to be_empty }
    end

    context 'when a TimeTable is scheduled on the given date' do
      let(:time_table) { referential.time_tables.first }
      let(:scheduled_time_tables) { referential.time_tables.where(id: time_table) }

      before do
        allow(Chouette::TimeTable).to receive(:scheduled_on).and_return(scheduled_time_tables)
      end

      it { is_expected.to contain_exactly(vehicle_journey) }
    end

    context 'when two TimeTables is scheduled on the given date' do
      let(:scheduled_time_tables) { referential.time_tables }

      before do
        allow(Chouette::TimeTable).to receive(:scheduled_on).and_return(scheduled_time_tables)
      end

      it { is_expected.to contain_exactly(vehicle_journey) }
    end
  end
end

# DEPRECATED

describe Chouette::VehicleJourney, type: :model do
  subject { create(:vehicle_journey) }
  before(:each){
    Chouette::VehicleJourney.reset_custom_fields
  }

  it "must be valid with an at-stop day offset of 1" do
    vehicle_journey = create(
      :vehicle_journey,
      stop_arrival_time: '23:00:00',
      stop_departure_time: '23:00:00'
    )
    vehicle_journey.vehicle_journey_at_stops.last.update(
      arrival_time: '00:30:00',
      departure_time: '00:30:00',
      arrival_day_offset: 1,
      departure_day_offset: 1
    )

    expect(vehicle_journey).to be_valid
  end

  it 'must validate before being persisted' do
    vehicle_journey = create(:vehicle_journey)

    vehicle_journey.vehicle_journey_at_stops.build(
      arrival_time: '01:30:00',
      departure_time: '01:30:00',
      arrival_day_offset: 0,
      departure_day_offset: 0,
      stop_point: vehicle_journey.route.stop_points.first,
      vehicle_journey: nil # this is silly, but we use it to test a bug on the ChecksumManager
    )

    vehicle_journey.vehicle_journey_at_stops.build(
      arrival_time: '00:30:00',
      departure_time: '00:30:00',
      arrival_day_offset: 0,
      departure_day_offset: 0,
      stop_point: vehicle_journey.route.stop_points.last,
      vehicle_journey: nil # this is silly, but we use it to test a bug on the ChecksumManager
    )

    expect{ vehicle_journey.validate }.to_not raise_error
  end

  describe "search by short_id" do
    let(:referential){ create :referential }
    let(:route){ create :route, referential: referential }
    let(:journey_pattern){ create :journey_pattern, route: route }
    let(:vehicle_journey){ create( :vehicle_journey, objectid: objectid, journey_pattern: journey_pattern)}
    let(:objectid){ "AAAA:BBBB:CCCC-EEE-FFF:DDDD" }

    before(:each){
      referential.switch
      vehicle_journey
    }
    context "with a netex referential" do
      before(:each) do
        referential.update objectid_format: "netex"
      end

      it "should search on the local_id" do
        expect(Chouette::VehicleJourney.with_short_id('AAA')).to be_empty
        expect(Chouette::VehicleJourney.with_short_id('CCC')).to include vehicle_journey
        expect(Chouette::VehicleJourney.with_short_id('EEE')).to be_empty
      end
    end

    context "with a stif_netex referential" do
      before(:each) do
        referential.update objectid_format: "stif_netex"
      end

      it "should search on the local_id" do
        expect(Chouette::VehicleJourney.with_short_id('AAA')).to be_empty
        expect(Chouette::VehicleJourney.with_short_id('CCC')).to include vehicle_journey
        expect(Chouette::VehicleJourney.with_short_id('EEE')).to be_empty
      end
    end

    context "with a stif_codifligne referential" do
      let(:objectid){ "STIF:CODIFLIGNE:CCC-EEE:LOC" }

      before(:each) do
        referential.update objectid_format: "stif_codifligne"
      end

      it "should search on the local_id" do
        expect(Chouette::VehicleJourney.with_short_id('AAA')).to be_empty
        expect(Chouette::VehicleJourney.with_short_id('CCC')).to include vehicle_journey
        expect(Chouette::VehicleJourney.with_short_id('EEE')).to include vehicle_journey
      end
    end

    context "with a stif_reflex referential" do
      let(:objectid){ "FR:33000:Line:CCC-EEE:LOC" }

      before(:each) do
        referential.update objectid_format: "stif_reflex"
      end

      it "should search on the local_id" do
        expect(Chouette::VehicleJourney.with_short_id('AAA')).to be_empty
        expect(Chouette::VehicleJourney.with_short_id('CCC')).to include vehicle_journey
        expect(Chouette::VehicleJourney.with_short_id('EEE')).to include vehicle_journey
      end
    end
  end

  describe 'checksum' do
    it_behaves_like 'checksum support'

    let(:checksum_owner){ create(:vehicle_journey) }

    it_behaves_like 'it works with both checksums modes',
                    "changes when a vjas is created",
                    ->{ create(:vehicle_journey_at_stop, vehicle_journey: checksum_owner) },
                    reload: true

    it_behaves_like 'it works with both checksums modes',
                    "changes when a vjas is updated",
                    ->{ checksum_owner.vehicle_journey_at_stops.last.update_attribute(:departure_time, Time.now) },
                    reload: true

    it_behaves_like 'it works with both checksums modes',
                    "changes when a vjas is deleted",
                    -> {
                      vjas = checksum_owner.vehicle_journey_at_stops.last
                      vjas.destroy
                    },
                    reload: true

    it_behaves_like 'it works with both checksums modes',
                    "changes when a footnote is added",
                    -> {
                      footnote = create :footnote
                      checksum_owner.footnotes << footnote
                      checksum_owner.save
                    },
                    reload: true

    it_behaves_like 'it works with both checksums modes',
                    "changes when a footnote is updated",
                    -> { footnote.reload.update(label: "mkmkmk") },
                    reload: true do
        let(:footnote){ create :footnote }
        before { checksum_owner.footnotes << footnote }
    end

    it_behaves_like 'it works with both checksums modes',
                    "changes when a footnote is deleted",
                    -> {
                      footnote.destroy
                    },
                    reload: true do
        let(:footnote){ create :footnote }
        before do
          checksum_owner.footnotes << footnote
          checksum_owner.save
          footnote.reload
        end
    end

    it_behaves_like 'it works with both checksums modes',
                    "changes when a line_notice is added",
                    -> {
                      line_notice = create :line_notice
                      checksum_owner.line_notices = [line_notice]
                      checksum_owner.save
                    },
                    reload: true

    it_behaves_like 'it works with both checksums modes',
                    "changes when a line_notice is updated",
                    -> { line_notice.reload.update(objectid: "foo:LineNotice:2:LOC") },
                    reload: true do
        let(:line_notice){ create :line_notice }
        before { checksum_owner.update line_notices: [line_notice] }
    end

    it_behaves_like 'it works with both checksums modes',
                    "changes when a line_notice is deleted",
                    -> {
                      line_notice.destroy
                    },
                    reload: true do
        let(:line_notice){ create :line_notice }
        before do
          checksum_owner.update line_notices: [line_notice]
          line_notice.reload
        end
    end

    it_behaves_like 'it works with both checksums modes',
                    "changes when a RoutingConstraintZone is deleted",
                    -> {
                      rcz.destroy
                    },
                    reload: true do
        let(:rcz){ create :routing_constraint_zone, route_id: checksum_owner.route.id }
        before(:each) do
          checksum_owner.ignored_routing_contraint_zone_ids = [rcz.id]
          checksum_owner.save!
          rcz.reload
        end
    end

    it_behaves_like 'it works with both checksums modes',
                    "changes when a RoutingConstraintZone is updated",
                    -> {
                      rcz.stop_points << checksum_owner.route.stop_points.last
                      rcz.save!
                    },
                    reload: true do
        let(:rcz){ create :routing_constraint_zone, route_id: checksum_owner.route.id, stop_points: checksum_owner.route.stop_points[0..1] }
        before(:each) do
          checksum_owner.ignored_routing_contraint_zone_ids = [rcz.id]
          checksum_owner.save!
          rcz.reload
        end
    end

    it_behaves_like 'it works with both checksums modes',
                    "changes when a StopAreaRoutingConstraint is added",
                    -> {
                      checksum_owner.ignored_stop_area_routing_constraints = [constraint_zone.id]
                      checksum_owner.save
                    },
                    reload: true do
        let(:constraint_zone){ create :stop_area_routing_constraint, stop_area_provider: checksum_owner.referential.workbench.default_stop_area_provider }
    end

    it_behaves_like 'it works with both checksums modes',
                    "changes when a StopAreaRoutingConstraint is deleted",
                    -> {
                      constraint_zone.destroy
                      constraint_zone.run_callbacks(:commit)
                    },
                    reload: true do
        let(:constraint_zone){ create :stop_area_routing_constraint, stop_area_provider: checksum_owner.referential.workbench.default_stop_area_provider }
        before(:each) do
          checksum_owner.ignored_stop_area_routing_constraints = [constraint_zone.id]
          checksum_owner.save!
          constraint_zone.reload
        end
    end

    it_behaves_like 'it works with both checksums modes',
                    "changes when a StopAreaRoutingConstraint is updated",
                    -> {
                      constraint_zone.from = create(:stop_area, stop_area_referential: checksum_owner.referential.stop_area_referential)
                      constraint_zone.save!
                    },
                    reload: true do
        let(:constraint_zone){ create :stop_area_routing_constraint, stop_area_provider: checksum_owner.referential.workbench.default_stop_area_provider }
        before(:each) do
          checksum_owner.ignored_stop_area_routing_constraints = [constraint_zone.id]
          checksum_owner.save!
          constraint_zone.reload
        end
    end

    context "when a custom_field is added" do
      # CustomField don't trigger an automoatic checksum calcultation, we need to force it

      let(:checksum_owner){ create(:vehicle_journey, custom_field_values: {}) }
      context "when the custom_field has the :ignore_empty_value_in_checksums option enabled" do
        let(:custom_field) do
           create :custom_field,
                  field_type: :string,
                  code: :energy_ignored,
                  name: :energy,
                  resource_type: "VehicleJourney",
                  options: { ignore_empty_value_in_checksums: true }
         end

         it_behaves_like 'it works with both checksums modes',
                        "should not change the checksum",
                        -> { custom_field; Chouette::ChecksumManager.watch(checksum_owner); checksum_owner.save },
                        change: false
      end

      context "when the custom_field hasn't the :ignore_empty_value_in_checksums option enabled" do
        let(:custom_field) do
           create :custom_field,
                  field_type: :string,
                  code: :energy,
                  name: :energy,
                  resource_type: "VehicleJourney"
         end

         it_behaves_like 'it works with both checksums modes',
                        "should change the checksum",
                        -> { custom_field; Chouette::ChecksumManager.watch(checksum_owner); checksum_owner.save }

      end
    end

    context "when custom_field_values change" do
      let(:checksum_owner){ create(:vehicle_journey, custom_field_values: {custom_field.code.to_s => former_value}) }
      let(:custom_field){ create :custom_field, field_type: :string, code: :energy, name: :energy, resource_type: "VehicleJourney" }
      let(:former_value){ "foo" }
      let(:value){ "bar" }

      it_behaves_like 'it works with both checksums modes',
                     "should change the checksum",
                     -> {
                       checksum_owner.custom_field_values = {custom_field.code.to_s => value}
                       checksum_owner.save
                     }


      context "with an attachment custom_field" do
        let(:checksum_owner) do
          custom_field
          vj = create(:vehicle_journey)
          vj.custom_field_energy = File.open(fixtures_path("test_1/file.txt"))
          vj.save
          vj
        end
        let(:custom_field){ create :custom_field, field_type: :attachment, code: :energy, name: :energy, resource_type: "VehicleJourney" }

        after(:each) do
          to_be_deleted = Chouette::VehicleJourney.__callbacks[:commit].select {|call| call.instance_variable_get('@key') =~ /custom_field/ }
          to_be_deleted.each do |callback|
            Chouette::VehicleJourney.__callbacks[:commit].delete callback
          end
        end

        it_behaves_like 'it works with both checksums modes',
                       "should change the checksum",
                       -> {
                         checksum_owner.custom_field_energy = File.open(fixtures_path("test_2/file.txt"))
                         checksum_owner.save
                       }

        it_behaves_like 'it works with both checksums modes',
                       "should not change the checksum",
                       -> { checksum_owner.reload.save },
                       change: false
      end
    end
  end

  describe "#with_stop_area_ids" do
    subject(:result){Chouette::VehicleJourney.with_stop_area_ids(ids)}
    let(:ids){[]}
    let(:common_stop_area){ create :stop_area}
    let!(:journey_1){ create :vehicle_journey }
    let!(:journey_2){ create :vehicle_journey }

    before(:each) do
      journey_1.journey_pattern.stop_points.last.update_attribute :stop_area_id, common_stop_area.id
      journey_2.journey_pattern.stop_points.last.update_attribute :stop_area_id, common_stop_area.id
      expect(journey_1.stop_areas).to include(common_stop_area)
      expect(journey_2.stop_areas).to include(common_stop_area)
    end
    context "with no value" do
      it "should return all journeys" do
        expect(result).to eq Chouette::VehicleJourney.all
      end
    end

    context "with a single value" do
      let(:ids){[journey_1.stop_areas.first.id]}
      it "should return all journeys" do
        expect(result).to eq [journey_1]
      end

      context "with a common area" do
        let(:ids){[common_stop_area.id]}
        it "should return all journeys" do
          expect(result.to_a.sort).to eq [journey_1, journey_2].sort
        end
      end
    end

    context "with a couple of values" do
      let(:ids){[journey_1.stop_areas.first.id, common_stop_area.id]}
      it "should return only the matching journeys" do
        expect(result).to eq [journey_1]
      end
    end

  end

  describe '#in_time_table' do
    let(:start_date){2.month.ago.to_date}
    let(:end_date){1.month.ago.to_date}

    subject{Chouette::VehicleJourney.with_matching_timetable start_date..end_date}

    context "without time table" do
      let!(:vehicle_journey){ create :vehicle_journey }
      it "should not include VJ " do
        expect(subject).to_not include vehicle_journey
      end
    end

    context "without a time table matching on a regular day" do
      let(:timetable){
        period = create :time_table_period, period_start: start_date-2.day, period_end: start_date
        create :time_table, periods: [period], dates_count: 0
      }
      let!(:vehicle_journey){ create :vehicle_journey, time_tables: [timetable] }
      it "should include VJ " do
        expect(subject).to include vehicle_journey
      end
    end

    context "without a time table matching on a regular day" do
      let(:timetable){
        period = create :time_table_period, period_start: end_date, period_end: end_date+1.day
        create :time_table, periods: [period], dates_count: 0
      }
      let!(:vehicle_journey){ create :vehicle_journey, time_tables: [timetable] }
      it "should include VJ " do
        expect(subject).to include vehicle_journey
      end
    end

    context "with a time table with a matching period but not the right day" do
      let(:timetable){
        period = create :time_table_period, period_start: end_date - 1.day, period_end: end_date + 14.day
        create :time_table, :empty, periods: [period], int_day_types: 0, dates_count: 0
      }
      let!(:vehicle_journey){ create :vehicle_journey, time_tables: [timetable] }
      it "should not include VJ " do
        expect(subject).to_not include vehicle_journey
      end
    end

    context "with a time table with a matching period but day opted-out" do
      let(:start_date){end_date - 1.day}
      let(:end_date){Time.now.end_of_week.to_date}

      let(:timetable){
        tt = create :time_table, dates_count: 0, periods_count: 0
        create :time_table_period, period_start: start_date-1.month, period_end: start_date, time_table: tt
        create(:time_table_date, :date => start_date, in_out: false, time_table: tt)
        tt
      }
      let!(:vehicle_journey){ create :vehicle_journey, time_tables: [timetable] }
      it "should not include VJ " do
        expect(subject).to_not include vehicle_journey
      end
    end

    context "with a time table with no matching period but the right extra day" do
      let(:start_date){end_date - 1.day}
      let(:end_date){Time.now.end_of_week.to_date}

      let(:timetable){
        tt = create :time_table, dates_count: 0, periods_count: 0
        create :time_table_period, period_start: start_date-1.month, period_end: start_date-1.day, time_table: tt
        create(:time_table_date, :date => start_date, in_out: true, time_table: tt)
        tt
      }
      let!(:vehicle_journey){ create :vehicle_journey, time_tables: [timetable] }
      it "should include VJ " do
        expect(subject).to include vehicle_journey
      end
    end

  end

  describe 'order by time' do
    let(:referential){ create :referential }
    let(:route){ create :route, referential: referential }
    let(:journey_pattern){ create :journey_pattern, route: route }
    let(:vj1) { create(
      :vehicle_journey,
      journey_pattern: journey_pattern,
      stop_arrival_time: '10:00:00',
      stop_departure_time: '10:00:00'
    ) }
    let(:vj2) { create(
      :vehicle_journey,
      journey_pattern: journey_pattern,
      stop_arrival_time: '11:00:00',
      stop_departure_time: '11:00:00'
    ) }
    let(:vj3) { create(
      :vehicle_journey,
      journey_pattern: journey_pattern,
      stop_arrival_time: '23:00:00',
      stop_departure_time: '00:10:00'
    ) }

    before(:each){
      referential.switch
      referential.vehicle_journeys.to_a.push(vj1, vj2, vj3)
    }

    context '#order_by_departure_time' do
      it 'should order vehicle journeys by vjas departure time' do
        vj3.vehicle_journey_at_stops.each do |vjas|
          vjas.update(departure_day_offset: 1)
        end

        asc_result = Chouette::VehicleJourney.order_by_departure_time('asc')
        expect(asc_result.length).to eq(3)
        expect(asc_result.first.id).to eq(vj1.id)
        expect(asc_result.last.id).to eq(vj3.id)

        desc_result = Chouette::VehicleJourney.order_by_departure_time('desc')
        expect(desc_result.length).to eq(3)
        expect(desc_result.first.id).to eq(vj3.id)
        expect(desc_result.last.id).to eq(vj1.id)
      end
    end

    context '#order_by_arrival_time' do
      it 'should order vehicle journeys by vjas arrival time' do
        vj3.vehicle_journey_at_stops.reject {|vjas| vjas == vj3.vehicle_journey_at_stops.first }.each do |vjas|
          vjas.update(arrival_day_offset: 1)
        end

        asc_result = Chouette::VehicleJourney.order_by_arrival_time('asc')
        expect(asc_result.length).to eq(3)
        expect(asc_result.first.id).to eq(vj1.id)
        expect(asc_result.last.id).to eq(vj3.id)

        desc_result = Chouette::VehicleJourney.order_by_arrival_time('desc')
        expect(desc_result.length).to eq(3)
        expect(desc_result.first.id).to eq(vj3.id)
        expect(desc_result.last.id).to eq(vj1.id)
      end
    end
  end

  describe "vjas_departure_time_must_be_before_next_stop_arrival_time" do
    let(:context) do
      Chouette.create do
        vehicle_journey
      end
    end

    let(:vehicle_journey) { context.vehicle_journey }

    context 'when second vehicle_journey_at_stop day offset is 1' do
      before(:each) do
        second_vjas = vehicle_journey.vehicle_journey_at_stops.second
        second_vjas.departure_day_offset = 1
        second_vjas.arrival_day_offset = 1
      end

      it 'returns true and vehicle journey should be valid' do
        vehicle_journey.validate

        expect(vehicle_journey).to be_valid
        expect(vehicle_journey.vjas_departure_time_must_be_before_next_stop_arrival_time).to be_truthy
      end

      context 'and first vehicle journey at stop departure and arrival time are 22:55:00 and next one 00:05:00' do
        before(:each) do
          first_vjas = vehicle_journey.vehicle_journey_at_stops.first
          first_vjas.arrival_time = "2000-01-01 22:55:00 UTC"
          first_vjas.departure_time = "2000-01-01 22:55:00 UTC"
          second_vjas = vehicle_journey.vehicle_journey_at_stops.second
          second_vjas.departure_day_offset = 1
          second_vjas.arrival_day_offset = 1
          second_vjas.arrival_time = "2000-01-01 00:05:00 UTC"
          second_vjas.departure_time = "2000-01-01 00:05:00 UTC"
        end

        it 'returns true and vehicle journey should be valid' do
          vehicle_journey.validate

          expect(vehicle_journey).to be_valid
          expect(vehicle_journey.vjas_departure_time_must_be_before_next_stop_arrival_time).to be_truthy
        end
      end
    end

    context 'when all vehicle_journey_at_stop have a day offset 0' do
      it 'returns true and vehicle journey should be valid' do
        expect(vehicle_journey).to be_valid
        expect(vehicle_journey.vjas_departure_time_must_be_before_next_stop_arrival_time).to be_truthy
      end
    end
  end

  describe "state_update" do
    def vehicle_journey_at_stop_to_state vjas
      at_stop = {'stop_area_object_id' => vjas.stop_point.stop_area.objectid }
      [:id, :connecting_service_id, :boarding_alighting_possibility].map do |att|
        at_stop[att.to_s] = vjas.send(att) unless vjas.send(att).nil?
      end

      at_stop["stop_point_objectid"] = vjas&.stop_point&.objectid

      [:arrival, :departure].map do |att|
        at_stop["#{att}_time"] = {
          'hour'   => vjas.send("#{att}_local_time").strftime('%H'),
          'minute' => vjas.send("#{att}_local_time").strftime('%M'),
        }
      end
      at_stop
    end

    def vehicle_journey_to_state vj, line_notices=false
      vj.slice('objectid', 'published_journey_name', 'journey_pattern_id', 'company_id').tap do |item|
        item['vehicle_journey_at_stops'] = []
        item['time_tables']              = []
        item['footnotes']                = []
        item['line_notices']             = [] if line_notices
        item['referential_codes']        = []
        item['custom_fields']            = vj.custom_fields.to_hash

        vj.vehicle_journey_at_stops.each do |vjas|
          item['vehicle_journey_at_stops'] << vehicle_journey_at_stop_to_state(vjas)
        end
      end
    end

    let(:route)           { create :route }
    let(:journey_pattern) { create :journey_pattern, route: route }
    let(:vehicle_journey) { create :vehicle_journey, route: route, journey_pattern: journey_pattern }
    let(:line_notices)    { false }
    let(:state)           { vehicle_journey_to_state(vehicle_journey, line_notices) }
    let(:collection)      { [state.dup] }

    it 'should create new vj from state' do
      create(:custom_field, code: :energy)
      new_vj = build(:vehicle_journey, objectid: nil, published_journey_name: 'dummy', route: route, journey_pattern: journey_pattern, custom_field_values: {energy: 99})
      collection << vehicle_journey_to_state(new_vj)
      expect {
        Chouette::VehicleJourney.state_update(route, collection)
      }.to change {Chouette::VehicleJourney.count}.by(1)

      obj = Chouette::VehicleJourney.last
      expect(obj).to receive(:after_commit_objectid).and_call_original

      # For some reason we have to force it
      obj.after_commit_objectid

      expect(collection.last['objectid']).to eq obj.objectid
      expect(obj.published_journey_name).to eq 'dummy'
      expect(obj.custom_fields["energy"].value).to eq 99
    end

    it 'should expect local times' do
      new_vj = build(:vehicle_journey, objectid: nil, published_journey_name: 'dummy', route: route, journey_pattern: journey_pattern)
      stop_area = create(:stop_area, time_zone: "America/Mexico_City")
      stop_point = create(:stop_point, stop_area: stop_area)
      new_vj.vehicle_journey_at_stops << build(:vehicle_journey_at_stop, vehicle_journey: vehicle_journey, stop_point: stop_point)
      data = vehicle_journey_to_state(new_vj)
      data['vehicle_journey_at_stops'][0]["departure_time"]["hour"] = "15"
      data['vehicle_journey_at_stops'][0]["arrival_time"]["hour"] = "12"
      collection << data
      expect {
        Chouette::VehicleJourney.state_update(route, collection)
      }.to change {Chouette::VehicleJourney.count}.by(1)
      created = Chouette::VehicleJourney.last.vehicle_journey_at_stops.last
      expect(created.stop_point).to eq stop_point
      expect(created.departure_local_time.hour).to_not eq created.departure_time.hour
      expect(created.arrival_local_time.hour).to_not eq created.arrival_time.hour
      expect(created.departure_local_time.hour).to eq 15
      expect(created.arrival_local_time.hour).to eq 12
    end

    it "should not be sensible to winter/summer time" do
      new_vj = build(:vehicle_journey, objectid: nil, published_journey_name: 'dummy', route: route, journey_pattern: journey_pattern)
      stop_area = create(:stop_area, time_zone: 'Europe/Paris')
      stop_point = create(:stop_point, stop_area: stop_area)
      new_vj.vehicle_journey_at_stops << build(:vehicle_journey_at_stop, vehicle_journey: vehicle_journey, stop_point: stop_point)
      data = vehicle_journey_to_state(new_vj)
      data['vehicle_journey_at_stops'][0]["departure_time"]["hour"] = "15"
      data['vehicle_journey_at_stops'][0]["arrival_time"]["hour"] = "12"
      collection << JSON.parse(data.to_json)

      Timecop.freeze('2000/08/01 12:00:00'.to_time) do
        Chouette::VehicleJourney.state_update(route, collection.dup)
        created = Chouette::VehicleJourney.last.vehicle_journey_at_stops.last
        expect(created.departure_local_time.hour).to eq 15
        expect(created.arrival_local_time.hour).to eq 12
      end

      collection = [state, data]

      Chouette::VehicleJourney.last.destroy

      Timecop.freeze('2000/12/01 12:00:00'.to_time) do
        Chouette::VehicleJourney.state_update(route, collection)
        created = Chouette::VehicleJourney.last.vehicle_journey_at_stops.last
        expect(created.departure_local_time.hour).to eq 15
        expect(created.arrival_local_time.hour).to eq 12
      end
    end

    it 'should save vehicle_journey_at_stops of newly created vj' do
      new_vj = build(:vehicle_journey, objectid: nil, published_journey_name: 'dummy', route: route, journey_pattern: journey_pattern)
      new_vj.vehicle_journey_at_stops << build(:vehicle_journey_at_stop,
                 :vehicle_journey => new_vj,
                 :stop_point      => create(:stop_point),
                 :arrival_time    => '2000-01-01 01:00:00 UTC',
                 :departure_time  => '2000-01-01 03:00:00 UTC')

      collection << vehicle_journey_to_state(new_vj)
      expect {
        Chouette::VehicleJourney.state_update(route, collection)
      }.to change {Chouette::VehicleJourneyAtStop.count}.by(1)
    end

    it 'should update vj journey_pattern association' do
      state['journey_pattern'] = create(:journey_pattern).slice('id', 'name', 'objectid')
      Chouette::VehicleJourney.state_update(route, collection)

      expect(state['errors']).to be_nil
      expect(vehicle_journey.reload.journey_pattern_id).to eq state['journey_pattern']['id']
    end

    it 'should update vj time_tables association from state' do
      2.times{state['time_tables'] << create(:time_table).slice('id', 'comment', 'objectid')}
      vehicle_journey.update_has_and_belongs_to_many_from_state(state)

      expected = state['time_tables'].map{|tt| tt['id']}
      actual   = vehicle_journey.reload.time_tables.map(&:id)
      expect(actual).to match_array(expected)
    end

    context 'with line_notices' do
      let(:line_notices){ true }

      it 'should update vj line_notices association from state' do
        2.times{state['line_notices'] << create(:line_notice).slice('id')}
        vehicle_journey.update_has_and_belongs_to_many_from_state(state)
        vehicle_journey.save
        expected = state['line_notices'].map{|tt| tt['id']}
        actual   = vehicle_journey.reload.line_notices.map(&:id)
        expect(actual).to match_array(expected)
      end
    end

    context 'with referential_codes' do
      let(:code_space) { create(:code_space, workgroup: Workgroup.first) }
      let(:referential_code) { create(:referential_code, code_space: code_space, resource: vehicle_journey, resource_type: "Chouette::VehicleJourney") }

      it 'should clear vj referential_codes when deleted from state' do
        vehicle_journey.codes << create(:referential_code, code_space: code_space, resource: vehicle_journey, resource_type: "Chouette::VehicleJourney")
        referential_codes_count = ReferentialCode.count
        state['referential_codes'] = []
        vehicle_journey.manage_referential_codes_from_state(state)

        expect(ReferentialCode.count).to eq referential_codes_count - 1
        expect(vehicle_journey.reload.codes).to be_empty
      end

      it 'should update vj referential_codes association from state' do
        2.times{state['referential_codes'] << build(:referential_code, code_space: code_space, resource: vehicle_journey, resource_type: "Chouette::VehicleJourney").slice(:value, :code_space_id)}
        referential_codes_count = ReferentialCode.count
        vehicle_journey.manage_referential_codes_from_state(state)
        expect(ReferentialCode.count).to eq(referential_codes_count+2)
        expect(vehicle_journey.reload.codes.count).to eq (state['referential_codes'].count)
      end
    end

    it 'should clear vj time_tableas association when remove from state' do
      vehicle_journey.time_tables << create(:time_table)
      state['time_tables'] = []
      vehicle_journey.update_has_and_belongs_to_many_from_state(state)

      expect(vehicle_journey.reload.time_tables).to be_empty
    end

    it 'should update vj footnote association from state' do
      2.times{state['footnotes'] << create(:footnote, line: route.line).slice('id', 'code', 'label', 'line_id')}
      vehicle_journey.update_has_and_belongs_to_many_from_state(state)

      expect(vehicle_journey.reload.footnotes.map(&:id)).to eq(state['footnotes'].map{|tt| tt['id']})
    end

    it 'should clear vj footnote association from state' do
      vehicle_journey.footnotes << create(:footnote)
      state['footnotes'] = []
      vehicle_journey.update_has_and_belongs_to_many_from_state(state)

      expect(vehicle_journey.reload.footnotes).to be_empty
    end

    it 'should update vj company' do
      state['company'] = create(:company).slice('id', 'name', 'objectid')
      Chouette::VehicleJourney.state_update(route, collection)

      expect(state['errors']).to be_nil
      expect(vehicle_journey.reload.company_id).to eq state['company']['id']
    end

    it "handles vehicle journey company deletion" do
      vehicle_journey.update(company: create(:company))
      state.delete('company')
      Chouette::VehicleJourney.state_update(route, collection)

      expect(vehicle_journey.reload.company_id).to be_nil
    end

    it 'should update vj attributes from state' do
      state['published_journey_name']       = 'edited_name'
      state['published_journey_identifier'] = 'edited_identifier'
      state['custom_fields'] = {energy: {value: 99}}
      create :custom_field, field_type: :integer, code: :energy, name: :energy
      Chouette::VehicleJourney.reset_custom_fields

      Chouette::VehicleJourney.state_update(route, collection)
      expect(state['errors']).to be_nil
      expect(vehicle_journey.reload.published_journey_name).to eq state['published_journey_name']
      expect(vehicle_journey.reload.published_journey_identifier).to eq state['published_journey_identifier']

      expect(vehicle_journey.reload.custom_field_value("energy")).to eq 99
    end

    it 'should return errors when validation failed' do
      state['published_journey_name'] = 'edited_name'
      state['vehicle_journey_at_stops'].last['departure_time']['hour'] = '23'

      expect {
        Chouette::VehicleJourney.state_update(route, collection)
      }.not_to change(vehicle_journey, :published_journey_name)
      expect(state['vehicle_journey_at_stops'].last['errors']).not_to be_empty
    end

    it 'should delete vj with deletable set to true from state' do
      state['deletable'] = true
      collection         = [state]
      Chouette::VehicleJourney.state_update(route, collection)
      expect(collection).to be_empty
    end

    describe 'vehicle_journey_at_stops' do
      it 'should update departure_time' do
        item = state['vehicle_journey_at_stops'].first
        item['departure_time']['hour']   = "02"
        item['departure_time']['minute'] = "15"

        vehicle_journey.update_vjas_from_state(state['vehicle_journey_at_stops'])
        stop = vehicle_journey.vehicle_journey_at_stops.find(item['id'])

        expect(stop.departure_time.strftime('%H')).to eq item['departure_time']['hour']
        expect(stop.departure_time.strftime('%M')).to eq item['departure_time']['minute']
      end

      it 'should update arrival_time' do
        item = state['vehicle_journey_at_stops'].first
        item['arrival_time']['hour']   = (item['departure_time']['hour'].to_i - 1).to_s
        item['arrival_time']['minute'] = Time.now.strftime('%M')

        vehicle_journey.update_vjas_from_state(state['vehicle_journey_at_stops'])
        stop = vehicle_journey.vehicle_journey_at_stops.find(item['id'])

        expect(stop.arrival_time.strftime('%H').to_i).to eq item['arrival_time']['hour'].to_i
        expect(stop.arrival_time.strftime('%M')).to eq item['arrival_time']['minute']
      end

      it 'should return errors when validation failed' do
        # Arrival must be before departure time
        item = state['vehicle_journey_at_stops'].first
        item['arrival_time']['hour']   = "12"
        item['departure_time']['hour'] = "11"
        vehicle_journey.update_vjas_from_state(state['vehicle_journey_at_stops'])
        expect(item['errors'][:arrival_time].size).to eq 1
      end
    end

    describe '#vehicle_journey_at_stops_matrix' do
      it 'should fill missing vjas with dummy vjas' do
        vehicle_journey.journey_pattern.stop_points.delete_all
        vehicle_journey.vehicle_journey_at_stops.delete_all

        expect(vehicle_journey.reload.vehicle_journey_at_stops).to be_empty
        at_stops = vehicle_journey.reload.vehicle_journey_at_stops_matrix
        at_stops.map{|stop| expect(stop.id).to be_nil }
        expect(at_stops.count).to eq route.stop_points.count
      end

      it 'should set dummy to false for active stop_points vjas' do
        # Destroy vjas but stop_points is still active
        # it should fill a new vjas without dummy flag
        vehicle_journey.vehicle_journey_at_stops[3].destroy
        at_stops = vehicle_journey.reload.vehicle_journey_at_stops_matrix
        expect(at_stops[3].dummy).to be false
      end

      it 'should set dummy to true for deactivated stop_points vjas' do
        vehicle_journey.journey_pattern.stop_points.delete(vehicle_journey.journey_pattern.stop_points.first)
        at_stops = vehicle_journey.reload.vehicle_journey_at_stops_matrix
        expect(at_stops.first.dummy).to be true
      end

      it 'should fill vjas for active stop_points without vjas yet' do
        vehicle_journey.vehicle_journey_at_stops.destroy_all

        at_stops = vehicle_journey.reload.vehicle_journey_at_stops_matrix
        expect(at_stops.map(&:stop_point_id)).to eq vehicle_journey.journey_pattern.stop_points.map(&:id)
      end

      it 'should keep index order of vjas' do
        vehicle_journey.vehicle_journey_at_stops[3].destroy
        at_stops = vehicle_journey.reload.vehicle_journey_at_stops_matrix

        expect(at_stops[3].id).to be_nil
        at_stops.delete_at(3)
        at_stops.each do |stop|
          expect(stop.id).not_to be_nil
        end
      end
    end
  end

  describe ".with_stops" do
    def initialize_stop_times(vehicle_journey, &block)
      vehicle_journey
        .vehicle_journey_at_stops
        .each_with_index do |at_stop, index|
          at_stop.update(
            departure_time: at_stop.departure_time + block.call(index),
            arrival_time: at_stop.arrival_time + block.call(index)
          )
        end
    end

    it "selects vehicle journeys including stops in order or earliest departure time" do
      # Create later vehicle journey to give it a later id, such that it should
      # appear last if the order in the query isn't right.
      journey_late = create(:vehicle_journey)
      journey_early = create(
        :vehicle_journey,
        route: journey_late.route,
        journey_pattern: journey_late.journey_pattern
      )

      initialize_stop_times(journey_early) do |index|
        (index + 5).minutes
      end
      initialize_stop_times(journey_late) do |index|
        (index + 65).minutes
      end

      expected_journey_order = [journey_early, journey_late]

      expect(
        journey_late
          .route
          .vehicle_journeys
          .with_stops
          .to_a
      ).to eq(expected_journey_order)
    end

    it "orders journeys with nil times at the end" do
      journey_nil = create(:vehicle_journey_empty)
      journey = create(
        :vehicle_journey,
        route: journey_nil.route,
        journey_pattern: journey_nil.journey_pattern
      )

      expected_journey_order = [journey, journey_nil]

      expect(
        journey
          .route
          .vehicle_journeys
          .with_stops
          .to_a
      ).to eq(expected_journey_order)
    end

    it "journeys that skip the first stop(s) get ordered by the time of the \
        first stop that they make" do
      journey_missing_stop = create(:vehicle_journey)
      journey_early = create(
        :vehicle_journey,
        route: journey_missing_stop.route,
        journey_pattern: journey_missing_stop.journey_pattern
      )

      initialize_stop_times(journey_early) do |index|
        (index + 5).minutes
      end
      initialize_stop_times(journey_missing_stop) do |index|
        (index + 65).minutes
      end

      journey_missing_stop.vehicle_journey_at_stops.first.destroy

      expected_journey_order = [journey_early, journey_missing_stop]

      expect(
        journey_missing_stop
          .route
          .vehicle_journeys
          .with_stops
          .to_a
      ).to eq(expected_journey_order)
    end
  end

  describe ".where_departure_time_between" do
    it "selects vehicle journeys whose departure times are between the specified range" do
      journey_early = create(
        :vehicle_journey,
        stop_departure_time: '02:00:00'
      )

      route = journey_early.route
      journey_pattern = journey_early.journey_pattern

      journey_middle = create(
        :vehicle_journey,
        route: route,
        journey_pattern: journey_pattern,
        stop_departure_time: '03:00:00'
      )
      create(
        :vehicle_journey,
        route: route,
        journey_pattern: journey_pattern,
        stop_departure_time: '04:00:00'
      )

      expect(route
        .vehicle_journeys
        .select('DISTINCT "vehicle_journeys".*')
        .joins('
          LEFT JOIN "vehicle_journey_at_stops"
            ON "vehicle_journey_at_stops"."vehicle_journey_id" =
              "vehicle_journeys"."id"
        ')
        .where_departure_time_between('02:30', '03:30')
        .to_a
      ).to eq([journey_middle])
    end

    it "can include vehicle journeys that have nil stops" do
      journey = create(:vehicle_journey_empty)
      route = journey.route

      expect(route
        .vehicle_journeys
        .select('DISTINCT "vehicle_journeys".*')
        .joins('
          LEFT JOIN "vehicle_journey_at_stops"
            ON "vehicle_journey_at_stops"."vehicle_journey_id" =
              "vehicle_journeys"."id"
        ')
        .where_departure_time_between('02:30', '03:30', allow_empty: true)
        .to_a
      ).to eq([journey])
    end

    it "uses an inclusive range" do
      journey_early = create(
        :vehicle_journey,
        stop_departure_time: '03:00:00'
      )

      route = journey_early.route
      journey_pattern = journey_early.journey_pattern

      journey_late = create(
        :vehicle_journey,
        route: route,
        journey_pattern: journey_pattern,
        stop_departure_time: '04:00:00'
      )

      expect(route
        .vehicle_journeys
        .select('DISTINCT "vehicle_journeys".*')
        .joins('
          LEFT JOIN "vehicle_journey_at_stops"
            ON "vehicle_journey_at_stops"."vehicle_journey_id" =
              "vehicle_journeys"."id"
        ')
        .where_departure_time_between('03:00', '04:00', allow_empty: true)
        .to_a
      ).to match_array([journey_early, journey_late])
    end
  end

  describe ".without_time_tables" do
    it "selects only vehicle journeys that have no associated calendar" do
      journey = create(:vehicle_journey)
      route = journey.route

      journey_with_time_table = create(
        :vehicle_journey,
        route: route,
        journey_pattern: journey.journey_pattern
      )
      journey_with_time_table.time_tables << create(:time_table)

      expect(
        route
          .vehicle_journeys
          .without_time_tables
          .to_a
      ).to eq([journey])
    end
  end

  subject { create(:vehicle_journey_odd) }
  describe "in_relation_to_a_journey_pattern methods" do
    let!(:route) { create(:route)}
    let!(:journey_pattern) { create(:journey_pattern, :route => route)}
    let!(:journey_pattern_odd) { create(:journey_pattern_odd, :route => route)}
    let!(:journey_pattern_even) { create(:journey_pattern_even, :route => route)}

    context "when vehicle_journey is on odd stop whereas selected journey_pattern is on all stops" do
      subject { create(:vehicle_journey, :route => route, :journey_pattern => journey_pattern_odd)}
      describe "#extra_stops_in_relation_to_a_journey_pattern" do
        it "should be empty" do
          expect(subject.extra_stops_in_relation_to_a_journey_pattern( journey_pattern)).to be_empty
        end
      end
      describe "#extra_vjas_in_relation_to_a_journey_pattern" do
        it "should be empty" do
          expect(subject.extra_vjas_in_relation_to_a_journey_pattern( journey_pattern)).to be_empty
        end
      end
      describe "#missing_stops_in_relation_to_a_journey_pattern" do
        it "should return even stops" do
          result = subject.missing_stops_in_relation_to_a_journey_pattern( journey_pattern)
          expect(result).to eq(journey_pattern_even.stop_points)
        end
      end
      describe "#update_journey_pattern" do
        it "should new_record for added vjas" do
          subject.update_journey_pattern( journey_pattern)
          subject.vehicle_journey_at_stops.select{ |vjas| vjas.new_record? }.each do |vjas|
            expect(journey_pattern_even.stop_points).to include( vjas.stop_point)
          end
        end
        it "should add vjas on each even stops" do
          subject.update_journey_pattern( journey_pattern)
          vehicle_stops = subject.vehicle_journey_at_stops.map(&:stop_point)
          journey_pattern_even.stop_points.each do |sp|
            expect(vehicle_stops).to include(sp)
          end
        end
        it "should not mark any vjas as _destroy" do
          subject.update_journey_pattern( journey_pattern)
          expect(subject.vehicle_journey_at_stops.any?{ |vjas| vjas._destroy }).to be_falsey
        end
      end
    end
    context "when vehicle_journey is on all stops whereas selected journey_pattern is on odd stops" do
      subject { create(:vehicle_journey, :route => route, :journey_pattern => journey_pattern)}
      describe "#missing_stops_in_relation_to_a_journey_pattern" do
        it "should be empty" do
          expect(subject.missing_stops_in_relation_to_a_journey_pattern( journey_pattern_odd)).to be_empty
        end
      end
      describe "#extra_stops_in_relation_to_a_journey_pattern" do
        it "should return even stops" do
          result = subject.extra_stops_in_relation_to_a_journey_pattern( journey_pattern_odd)
          expect(result).to eq(journey_pattern_even.stop_points)
        end
      end
      describe "#extra_vjas_in_relation_to_a_journey_pattern" do
        it "should return vjas on even stops" do
          result = subject.extra_vjas_in_relation_to_a_journey_pattern( journey_pattern_odd)
          expect(result.map(&:stop_point)).to eq(journey_pattern_even.stop_points)
        end
      end
      describe "#update_journey_pattern" do
        it "should add no new vjas" do
          subject.update_journey_pattern( journey_pattern_odd)
          expect(subject.vehicle_journey_at_stops.any?{ |vjas| vjas.new_record? }).to be_falsey
        end
        it "should mark vehicle_journey_at_stops as _destroy on even stops" do
          subject.update_journey_pattern( journey_pattern_odd)
          subject.vehicle_journey_at_stops.each { |vjas|
            expect(vjas._destroy).to eq(journey_pattern_even.stop_points.include?(vjas.stop_point))
          }
        end
      end
    end
  end

  context "when following departure times exceeds gap" do
    describe "#update_attributes" do
      let!(:params){ {"vehicle_journey_at_stops_attributes" => {
            "0"=>{"id" => subject.vehicle_journey_at_stops[0].id ,"arrival_time" => 1.minutes.ago,"departure_time" => 1.minutes.ago},
            "1"=>{"id" => subject.vehicle_journey_at_stops[1].id, "arrival_time" => (1.minutes.ago + 4.hour),"departure_time" => (1.minutes.ago + 4.hour)}
         }}}
      it "should return false", :skip => "Time gap validation is in pending status" do
        expect(subject.update_attributes(params)).to be_falsey
      end
      it "should make instance invalid", :skip => "Time gap validation is in pending status" do
        subject.update_attributes(params)
        expect(subject).not_to be_valid
      end
      it "should let first vjas without any errors", :skip => "Time gap validation is in pending status" do
        subject.update_attributes(params)
        expect(subject.vehicle_journey_at_stops[0].errors).to be_empty
      end
      it "should add an error on second vjas", :skip => "Time gap validation is in pending status" do
        subject.update_attributes(params)
        expect(subject.vehicle_journey_at_stops[1].errors[:departure_time]).not_to be_blank
      end
    end
  end

  context "#time_table_tokens=" do
    let!(:tm1){create(:time_table, :comment => "TM1")}
    let!(:tm2){create(:time_table, :comment => "TM2")}

    it "should return associated time table ids" do
      subject.update_attributes :time_table_tokens => [tm1.id, tm2.id].join(',')
      expect(subject.time_tables).to include( tm1)
      expect(subject.time_tables).to include( tm2)
    end
  end

  describe "#bounding_dates" do
    before(:each) do
      tm1 = build(:time_table, :dates =>
                               [ build(:time_table_date, :date => 1.days.ago.to_date, :in_out => true),
                                 build(:time_table_date, :date => 2.days.ago.to_date, :in_out => true) ])
      tm2 = build(:time_table, :periods =>
                                [ build(:time_table_period, :period_start => 4.days.ago.to_date, :period_end => 3.days.ago.to_date)])
      tm3 = build(:time_table)
      subject.time_tables = [ tm1, tm2, tm3]
    end
    it "should return min date from associated calendars" do
      expect(subject.bounding_dates.min).to eq(4.days.ago.to_date)
    end
    it "should return max date from associated calendars" do
      expect(subject.bounding_dates.max).to eq(1.days.ago.to_date)
    end
  end

  context "#vehicle_journey_at_stops" do
    it "should be ordered like stop_points on route" do
      route = subject.route
      vj_stop_ids = subject.vehicle_journey_at_stops.map(&:stop_point_id)
      expected_order = route.stop_points.map(&:id).select {|s_id| vj_stop_ids.include?(s_id)}

      expect(vj_stop_ids).to eq(expected_order)
    end
  end

  describe "#footnote_ids=" do
    context "when line have footnotes, " do
      let!( :route) { create( :route ) }
      let!( :line) { route.line }
      let!( :footnote_first) {create( :footnote, :code => "1", :label => "dummy 1", :line => route.line)}
      let!( :footnote_second) {create( :footnote, :code => "2", :label => "dummy 2", :line => route.line)}

      it "should update vehicle's footnotes" do
        expect(Chouette::VehicleJourney.find(subject.id).footnotes).to be_empty
        subject.footnote_ids = [ footnote_first.id ]
        subject.save
        expect(Chouette::VehicleJourney.find(subject.id).footnotes.count).to eq(1)
      end
    end
  end

  def offset_passing_time time, offset
    new_time = (time + offset).utc
    "2000-01-01 #{new_time.hour}:#{new_time.min}:#{new_time.sec} UTC".to_time
  end

  describe "#fill_passing_times!" do
    before(:each) do
      @start_area = create :stop_area
      @border_area = create :stop_area, kind: :non_commercial, area_type: :border
      @border_2_area = create :stop_area, kind: :non_commercial, area_type: :border
      @middle_area = create :stop_area
      @border_3_area = create :stop_area, kind: :non_commercial, area_type: :border
      @border_4_area = create :stop_area, kind: :non_commercial, area_type: :border
      @end_area = create :stop_area
      journey_pattern = create :journey_pattern
      journey_pattern.stop_points.destroy_all
      journey_pattern.stop_points << start_point = create(:stop_point, stop_area: @start_area, position: 0)
      journey_pattern.stop_points << border_point = create(:stop_point, stop_area: @border_area, position: 1)
      journey_pattern.stop_points << border_point_2 = create(:stop_point, stop_area: @border_2_area, position: 2)
      journey_pattern.stop_points << middle_point = create(:stop_point, stop_area: @middle_area, position: 3)
      journey_pattern.stop_points << border_point_3 = create(:stop_point, stop_area: @border_3_area, position: 4)
      journey_pattern.stop_points << border_point_4 = create(:stop_point, stop_area: @border_4_area, position: 5)
      journey_pattern.stop_points << end_point = create(:stop_point, stop_area: @end_area, position: 6)
      journey_pattern.update_attribute :costs, {
        "#{start_point.stop_area_id}-#{border_point.stop_area_id}" => {distance: 50},
        "#{border_point.stop_area_id}-#{border_point_2.stop_area_id}" => {distance: 0},
        "#{border_point_2.stop_area_id}-#{middle_point.stop_area_id}" => {distance: 100},
        "#{middle_point.stop_area_id}-#{border_point_3.stop_area_id}" => {distance: 100},
        "#{border_point_3.stop_area_id}-#{border_point_4.stop_area_id}" => {distance: 0},
        "#{border_point_4.stop_area_id}-#{end_point.stop_area_id}" => {distance: 100}
      }
      @journey = create :vehicle_journey, journey_pattern: journey_pattern
      @journey.vehicle_journey_at_stops.destroy_all
      departure_time = Time.now.noon
      @start = create :vehicle_journey_at_stop, stop_point: start_point, vehicle_journey: @journey, departure_time: departure_time, arrival_time: departure_time
      @target = create :vehicle_journey_at_stop, stop_point: border_point, vehicle_journey: @journey, arrival_time: nil, departure_time: nil
      @target_2 = create :vehicle_journey_at_stop, stop_point: border_point_2, vehicle_journey: @journey, arrival_time: nil, departure_time: nil
      @middle = create :vehicle_journey_at_stop, stop_point: middle_point, vehicle_journey: @journey, arrival_time: @start.arrival_time + 4.hours, departure_time: @start.departure_time + 4.hours
      @target_3 = create :vehicle_journey_at_stop, stop_point: border_point_3, vehicle_journey: @journey, arrival_time: nil, departure_time: nil
      @target_4 = create :vehicle_journey_at_stop, stop_point: border_point_4, vehicle_journey: @journey, arrival_time: nil, departure_time: nil
      @end = create :vehicle_journey_at_stop, stop_point: end_point, vehicle_journey: @journey, arrival_time: offset_passing_time(@middle.arrival_time, 4.hours), departure_time: offset_passing_time(@middle.departure_time, 4.hours)
    end

    it "should compute passing time" do
      @journey.reload.fill_passing_times!
      expect(@target.reload.arrival_time.to_i).to eq offset_passing_time(@start.reload.departure_time, 1.0/3 * (@middle.reload.arrival_time - @start.departure_time)).to_i
      expect(@target_2.reload.arrival_time).to eq @target.arrival_time
      expect(@target.departure_time).to eq @target.arrival_time
      expect(@target_2.departure_time).to eq @target.arrival_time
      expect(@target_3.reload.arrival_time.to_i).to eq offset_passing_time(@middle.reload.departure_time, 0.5 * (@end.reload.arrival_time - @middle.departure_time)).to_i
      expect(@target_4.reload.arrival_time).to eq @target_3.arrival_time
      expect(@target_3.departure_time).to eq @target_3.arrival_time
      expect(@target_4.departure_time).to eq @target_3.arrival_time
    end

    context "with a stop across midnight" do
      before(:each) do
        @middle.update arrival_time: offset_passing_time(@start.departure_time, 11.hours), departure_time: offset_passing_time(@start.departure_time, 13.hours), departure_day_offset: 1, arrival_day_offset: 0
      end

      # #7275
      xit "should set the following stop day offset" do
        @journey.reload.fill_passing_times!
        expect(@target_3.reload.arrival_day_offset).to eq @middle.departure_day_offset
        expect(@target_3.departure_day_offset).to eq @middle.departure_day_offset
      end
    end

    context "with timezones" do
      before do
        @start_area.update time_zone: "Europe/Paris"
        @border_area.update time_zone: "Europe/Paris"
        @border_2_area.update time_zone: "Europe/Paris"
        @middle_area.update time_zone: "Europe/Paris"
        @border_3_area.update time_zone: "Europe/Paris"
        @border_4_area.update time_zone: "Europe/Paris"
        @end_area.update time_zone: "Europe/Paris"

        departure_time = Time.now.utc.noon + 10.hour + 30.minutes
        @start.update departure_time: departure_time, arrival_time: departure_time
        @middle.update departure_time: offset_passing_time(departure_time, 2.hours), arrival_time: offset_passing_time(departure_time, 2.hours)
        @end.update departure_time: offset_passing_time(departure_time, 4.hours), arrival_time: offset_passing_time(departure_time, 4.hours)
      end

      it "should compute passing time" do
        @journey.reload.calculate_vehicle_journey_at_stop_day_offset
        @journey.fill_passing_times!

        expect{
          Chouette::VehicleJourneyAtStopsDayOffset.new(@journey.vehicle_journey_at_stops).calculate!
        }.to_not change{
          @journey.vehicle_journey_at_stops.sort_by{|vj| vj.stop_point.position}.map(&:current_checksum_source).join(' ')
        }
      end
    end

    context "with a day offset" do
      before do
        @end.update arrival_time: offset_passing_time(@middle.departure_time, - 4.hours), departure_time: offset_passing_time(@middle.departure_time, - 4.hours), departure_day_offset: 1, arrival_day_offset: 1
      end

      it "should compute passing time" do
        @journey.reload.fill_passing_times!
        expect(@target.reload.arrival_time.to_i).to eq offset_passing_time(@start.reload.departure_time, 1.0/3 * (@middle.reload.arrival_time - @start.departure_time)).to_i
        expect(@target_2.reload.arrival_time).to eq @target.arrival_time
        expect(@target.departure_time).to eq @target.arrival_time
        expect(@target_2.departure_time).to eq @target.arrival_time
        expect(@target_3.reload.arrival_time.to_i).to eq offset_passing_time(@middle.reload.departure_time, 10.hours).to_i
        expect(@target_3.arrival_day_offset).to eq 1
        expect(@target_3.departure_day_offset).to eq 1
        expect(@target_4.reload.arrival_time).to eq @target_3.arrival_time
        expect(@target_3.departure_time).to eq @target_3.arrival_time
        expect(@target_4.departure_time).to eq @target_3.arrival_time
      end
    end

    context "with four holes" do
      before do
        @start_area = create :stop_area
        @start_area_2 = create :stop_area
        @border_area = create :stop_area, kind: :non_commercial, area_type: :border
        @border_2_area = create :stop_area, kind: :non_commercial, area_type: :border
        @border_3_area = create :stop_area, kind: :non_commercial, area_type: :border
        @border_4_area = create :stop_area, kind: :non_commercial, area_type: :border
        @middle_area = create :stop_area
        @end_area = create :stop_area
        journey_pattern = create :journey_pattern
        journey_pattern.stop_points.destroy_all
        journey_pattern.stop_points << start_point = create(:stop_point, stop_area: @start_area, position: 0)
        journey_pattern.stop_points << start_point_2 = create(:stop_point, stop_area: @start_area_2, position: 1)
        journey_pattern.stop_points << border_point = create(:stop_point, stop_area: @border_area, position: 2)
        journey_pattern.stop_points << border_point_2 = create(:stop_point, stop_area: @border_2_area, position: 3)
        journey_pattern.stop_points << border_point_3 = create(:stop_point, stop_area: @border_3_area, position: 4)
        journey_pattern.stop_points << border_point_4 = create(:stop_point, stop_area: @border_4_area, position: 5)
        journey_pattern.stop_points << middle_point = create(:stop_point, stop_area: @middle_area, position: 6)
        journey_pattern.stop_points << end_point = create(:stop_point, stop_area: @end_area, position: 7)
        journey_pattern.update_attribute :costs, {
          "#{start_point.stop_area_id}-#{start_point_2.stop_area_id}" => {distance: 232},
          "#{start_point_2.stop_area_id}-#{border_point.stop_area_id}" => {distance: 33},
          "#{border_point.stop_area_id}-#{border_point_2.stop_area_id}" => {distance: 0},
          "#{border_point_2.stop_area_id}-#{border_point_3.stop_area_id}" => {distance: 129},
          "#{border_point_3.stop_area_id}-#{border_point_4.stop_area_id}" => {distance: 0},
          "#{border_point_4.stop_area_id}-#{middle_point.stop_area_id}" => {distance: 84},
          "#{middle_point.stop_area_id}-#{end_point.stop_area_id}" => {distance: 58}
        }
        @journey = create :vehicle_journey, journey_pattern: journey_pattern
        @journey.vehicle_journey_at_stops.destroy_all
        @start    = create :vehicle_journey_at_stop, stop_point: start_point, vehicle_journey: @journey, arrival_time: "01/01/2000 10:30 UTC".to_time, departure_time: "01/01/2000 10:30 UTC".to_time
        @start_2  = create :vehicle_journey_at_stop, stop_point: start_point_2, vehicle_journey: @journey, arrival_time: "01/01/2000 13:25 UTC".to_time, departure_time: "01/01/2000 13:40 UTC".to_time
        @target   = create :vehicle_journey_at_stop, stop_point: border_point, vehicle_journey: @journey, arrival_time: nil, departure_time: nil
        @target_2 = create :vehicle_journey_at_stop, stop_point: border_point_2, vehicle_journey: @journey, arrival_time: nil, departure_time: nil
        @target_3 = create :vehicle_journey_at_stop, stop_point: border_point_3, vehicle_journey: @journey, arrival_time: nil, departure_time: nil
        @target_4 = create :vehicle_journey_at_stop, stop_point: border_point_4, vehicle_journey: @journey, arrival_time: nil, departure_time: nil
        @middle   = create :vehicle_journey_at_stop, stop_point: middle_point, vehicle_journey: @journey, arrival_time: "01/01/2000 17:35 UTC".to_time, departure_time: "01/01/2000 17:55 UTC".to_time
        @end      = create :vehicle_journey_at_stop, stop_point: end_point, vehicle_journey: @journey, arrival_time: "01/01/2000 18:55 UTC".to_time, departure_time: "01/01/2000 18:55 UTC".to_time
      end

      it "should compute passing time" do
        @journey.reload.fill_passing_times!
        expect{@journey.reload.calculate_vehicle_journey_at_stop_day_offset}.to_not change{ @journey.vehicle_journey_at_stops.map(&:checksum_source).join(' ') }
      end
    end
  end

  describe "#flattened_circulation_periods" do
    let(:origin){
      1.month.from_now.beginning_of_month.beginning_of_week.to_date
    }

    let(:time_table){
      time_table = create :time_table, int_day_types: ApplicationDaysSupport::MONDAY | ApplicationDaysSupport::TUESDAY
      time_table.periods.destroy_all
      time_table.dates.destroy_all
      time_table.periods.create period_start: origin, period_end: origin + 14.days
      time_table.periods.create period_start: origin + 19.days, period_end: origin + 29.days
      time_table.dates.destroy_all
      time_table
    }
    let(:time_table_2){
      time_table_2 = create :time_table, int_day_types: ApplicationDaysSupport::WEDNESDAY
      time_table_2.periods.destroy_all
      time_table_2.dates.destroy_all
      time_table_2.periods.create period_start: origin + 9.days, period_end: origin + 24.days
      time_table_2
    }
    let(:time_tables){ [time_table, time_table_2] }
    subject(:result){
      vehicle_journey.reload.flattened_circulation_periods.map{|r|
        [r.period_start.to_s, r.period_end.to_s, r.weekdays]
      }
    }
    let(:vehicle_journey){ create :vehicle_journey, time_tables: time_tables, published_journey_name: "Test" }
    let(:expected){
      [
        [origin.to_s, (origin+8.days).to_s, "1,1,0,0,0,0,0"],
        [(origin+9.days).to_s,  (origin+14.days).to_s, "1,1,1,0,0,0,0"],
        [(origin+16.days).to_s, (origin+16.days).to_s, "0,0,1,0,0,0,0"],
        [(origin+21.days).to_s, (origin+23.days).to_s, "1,1,1,0,0,0,0"],
        [(origin+28.days).to_s, (origin+29.days).to_s, "1,1,0,0,0,0,0"],
      ]
    }

    it { should eq expected }

    context "with dates exclusion" do
      let(:time_tables){ [time_table] }
      let(:time_table){
        time_table = create :time_table, int_day_types: ApplicationDaysSupport::MONDAY | ApplicationDaysSupport::TUESDAY
        time_table.dates.destroy_all
        time_table.periods.destroy_all
        time_table.periods.create period_start: origin, period_end: origin + 14.days
        time_table.dates.create date: origin + 7.days, in_out: false
        time_table
      }
      let(:expected){
        [
          [origin.to_s, (origin+1.days).to_s, "1,1,0,0,0,0,0"],
          [(origin+8.days).to_s, (origin+14.days).to_s, "1,1,0,0,0,0,0"],
        ]
      }
      it { should eq expected }
    end

    context "with dates exclusion on a single time_table" do
      let(:time_tables){ [time_table, time_table_2] }
      let(:time_table){
        time_table = create :time_table, int_day_types: ApplicationDaysSupport::MONDAY | ApplicationDaysSupport::TUESDAY
        time_table.dates.destroy_all
        time_table.periods.destroy_all
        time_table.periods.create period_start: origin, period_end: origin + 14.days
        time_table.dates.create date: origin + 9.days, in_out: false
        time_table
      }
      let(:time_table_2){
        time_table = create :time_table, int_day_types: ApplicationDaysSupport::WEDNESDAY
        time_table.dates.destroy_all
        time_table.periods.destroy_all
        time_table.periods.create period_start: origin, period_end: origin + 14.days
        time_table
      }
      let(:expected){
        [
          [origin.to_s, (origin+8.days).to_s, "1,1,1,0,0,0,0"],
          [(origin+9.days).to_s, (origin+9.days).to_s, "0,0,1,0,0,0,0"],
          [(origin+14.days).to_s, (origin+14.days).to_s, "1,1,1,0,0,0,0"],
        ]
      }
      it { should eq expected }
    end

    context "with dates inclusion" do
      let(:time_tables){ [time_table] }
      let(:origin){
        1.month.from_now.beginning_of_month.to_date.beginning_of_week  # a monday
      }
      let(:time_table){
        time_table = create :time_table, int_day_types: ApplicationDaysSupport::MONDAY | ApplicationDaysSupport::TUESDAY
        time_table.dates.destroy_all
        time_table.periods.destroy_all
        time_table.periods.create period_start: origin, period_end: origin + 14.days
        time_table.dates.create date: origin + 1.days, in_out: true
        time_table.dates.create date: origin + 17.days, in_out: true
        time_table
      }
      let(:expected){
        [
          [origin.to_s, (origin+14.days).to_s, "1,1,0,0,0,0,0"],
          [(origin+17.days).to_s, (origin+17.days).to_s, "1,1,0,1,0,0,0"],
        ]
      }
      it { should eq expected }
    end

    context "with dates inclusion and exclusion" do
      let(:time_tables){ [time_table, time_table_2] }
      let(:origin){
        1.month.from_now.beginning_of_month.to_date.beginning_of_week  # a monday
      }

      let(:time_table_2){
        time_table = create :time_table, int_day_types: ApplicationDaysSupport::MONDAY | ApplicationDaysSupport::TUESDAY
        time_table.dates.destroy_all
        time_table.periods.destroy_all
        time_table.periods.create period_start: origin, period_end: origin + 14.days
        time_table.dates.create date: origin + 30.days, in_out: false
        time_table.dates.create date: origin + 32.days, in_out: false
        time_table
      }

      let(:time_table){
        time_table = create :time_table, int_day_types: ApplicationDaysSupport::MONDAY | ApplicationDaysSupport::TUESDAY
        time_table.dates.destroy_all
        time_table.periods.destroy_all
        time_table.periods.create period_start: origin, period_end: origin + 14.days
        time_table.periods.create period_start: origin + 24.days, period_end: origin + 34.days
        time_table.dates.create date: origin + 1.days, in_out: true
        time_table.dates.create date: origin + 17.days, in_out: true
        time_table.dates.create date: origin + 30.days, in_out: false
        time_table
      }
      let(:expected){
        [
          [origin.to_s, (origin+14.days).to_s, "1,1,0,0,0,0,0"],
          [(origin+17.days).to_s, (origin+17.days).to_s, "1,1,0,1,0,0,0"],
          [(origin+28.days).to_s, (origin+29.days).to_s, "1,1,0,0,0,0,0"]
        ]
      }
      it { should eq expected }
    end

    context "with only dates inclusions" do
      let(:time_tables){ [time_table] }
      let(:time_table){
        time_table = create :time_table, int_day_types: 0
        time_table.dates.destroy_all
        time_table.periods.destroy_all
        time_table.dates.create date: origin.beginning_of_week, in_out: true
        time_table
      }
      let(:expected){
        [
          [origin.beginning_of_week.to_s, origin.beginning_of_week.to_s, "1,0,0,0,0,0,0"]
        ]
      }
      it { should eq expected }
    end

    context "with empty resulting periods" do
      let(:time_tables){ [time_table] }
      let(:time_table){
        time_table = create :time_table, int_day_types: ApplicationDaysSupport::MONDAY
        time_table.dates.destroy_all
        time_table.periods.destroy_all
        time_table.periods.create period_start: origin.beginning_of_week, period_end: origin.beginning_of_week + 30.days
        time_table.dates.create date: origin.beginning_of_week + 7.days, in_out: false
        time_table.dates.create date: origin.beginning_of_week + 14.days, in_out: false
        time_table.dates.create date: origin.beginning_of_week + 21.days, in_out: false
        time_table.dates.create date: origin.beginning_of_week + 28.days, in_out: false
        time_table
      }
      let(:expected){
        [
          [origin.beginning_of_week.to_s, origin.beginning_of_week.to_s, "1,0,0,0,0,0,0"]
        ]
      }
      it { should eq expected }
    end

    context "with a single resulting day" do
      let(:time_tables){ [time_table] }
      let(:time_table){
        time_table = create :time_table, int_day_types: ApplicationDaysSupport::MONDAY
        time_table.dates.destroy_all
        time_table.periods.destroy_all
        time_table.periods.create period_start: origin, period_end: origin + 6.days
        time_table
      }
      let(:expected){
        [
          [origin.to_s, origin.to_s, "1,0,0,0,0,0,0"]
        ]
      }
      it { should eq expected }
    end

    context "with 2 resulting days" do
      let(:time_tables){ [time_table] }
      let(:time_table){
        time_table = create :time_table, int_day_types: ApplicationDaysSupport::TUESDAY | ApplicationDaysSupport::THURSDAY
        time_table.dates.destroy_all
        time_table.periods.destroy_all
        time_table.periods.create period_start: origin, period_end: origin + 6.days
        time_table
      }
      let(:expected){
        [
          [(origin+1.day).to_s, (origin.+3.days).to_s, "0,1,0,1,0,0,0"]
        ]
      }
      it { should eq expected }
    end
  end

  describe "#clean!" do

    let(:context) do
      Chouette.create do
        time_table :time_table

        associations = {time_tables: [:time_table]}

        vehicle_journey :target, associations
        vehicle_journey :kept, associations
      end
    end

    let(:referential) { context.referential }

    let(:target) { context.vehicle_journey(:target) }
    let(:target_scope) { referential.vehicle_journeys.where(id: target) }

    let(:kept) { context.vehicle_journey(:kept) }

    before { referential.switch }

    it "destroys VehiculeJourneyAtStops associated to targeted VehiculeJourneys" do
      expect { target_scope.clean! }.to change {
        target.vehicle_journey_at_stops.exists?
      }
    end

    it "keeps VehiculeJourneyAtStops not associated to the targeted VehiculeJourneys" do
      expect { target_scope.clean! }.to_not change {
        kept.vehicle_journey_at_stops.exists?
      }
    end

    it "destroys targeted VehiculeJourneys" do
      expect { target_scope.clean! }.to change {
        referential.vehicle_journeys.exists?(target.id)
      }
    end

    it "keeps VehiculeJourneyAtStops not associated to the targeted VehiculeJourneys" do
      expect { target_scope.clean! }.to_not change {
        referential.vehicle_journeys.exists?(kept.id)
      }
    end


  end


end
