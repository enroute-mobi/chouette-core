require 'spec_helper'

describe Chouette::VehicleJourney, :type => :model do
  subject { create(:vehicle_journey) }

  it { is_expected.to be_versioned }
  it { should have_and_belong_to_many(:purchase_windows) }

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

  describe 'checksum' do
    it_behaves_like 'checksum support'
    it "changes when a vjas is updated" do
      vehicle_journey = create(:vehicle_journey)
      expect{vehicle_journey.vehicle_journey_at_stops.last.update_attribute(:departure_time, Time.now)}.to change{vehicle_journey.reload.checksum}
    end

    it "changes when a vjas is added" do
      vehicle_journey = create(:vehicle_journey)
      expect(vehicle_journey).to receive(:update_checksum_without_callbacks!).at_least(:once).and_call_original
      expect{create(:vehicle_journey_at_stop, vehicle_journey: vehicle_journey)}.to change{vehicle_journey.checksum}
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

  describe '#in_purchase_window' do
    let(:start_date){2.month.ago.to_date}
    let(:end_date){1.month.ago.to_date}

    subject{Chouette::VehicleJourney.in_purchase_window start_date..end_date}

    let!(:without_purchase_window){ create :vehicle_journey }
    let!(:without_matching_purchase_window){
      pw = create :purchase_window, referential: Referential.first, date_ranges: [(end_date+1.day..end_date+2.days)]
      pw2 = create :purchase_window, referential: Referential.first, date_ranges: [(end_date+10.day..end_date+20.days)]
      create :vehicle_journey, purchase_windows: [pw, pw2]
    }
    let!(:included_purchase_window){
      pw = create :purchase_window, referential: Referential.first, date_ranges: [(start_date..end_date)]
      pw2 = create :purchase_window, referential: Referential.first
      create :vehicle_journey, purchase_windows: [pw, pw2]
    }
    let!(:overlapping_purchase_window){
      pw = create :purchase_window, referential: Referential.first, date_ranges: [(end_date..end_date+1.day)]
      pw2 = create :purchase_window, referential: Referential.first
      create :vehicle_journey, purchase_windows: [pw, pw2]
    }


    it "should not include VJ with no purchase window" do
      expect(subject).to_not include without_purchase_window
    end

    it "should not include VJ with no matching purchase window" do
      expect(subject).to_not include without_matching_purchase_window
    end

    it "should include VJ with included purchase window" do
      expect(subject).to include included_purchase_window
    end

    it "should include VJ with overlapping purchase_window purchase window" do
      expect(subject).to include overlapping_purchase_window
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
      let(:start_date){end_date - 1.day}
      let(:end_date){Time.now.end_of_week.to_date}

      let(:timetable){
        period = create :time_table_period, period_start: start_date-1.month, period_end: end_date+1.month
        create :time_table, periods: [period], int_day_types: 4 + 8, dates_count: 0
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
        create :time_table_period, period_start: start_date-1.month, period_end: start_date-1.day, time_table: tt
        create(:time_table_date, :date => start_date, in_out: false, time_table: tt)
        tt
      }
      let!(:vehicle_journey){ create :vehicle_journey, time_tables: [timetable] }
      it "should not include VJ " do
        expect(subject).to_not include vehicle_journey
      end
    end

    context "with a time table with no matching period but not the right extra day" do
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

  describe "vjas_departure_time_must_be_before_next_stop_arrival_time",
      skip: "Validation currently commented out because it interferes with day offsets" do

    let(:vehicle_journey) { create :vehicle_journey }
    let(:vjas) { vehicle_journey.vehicle_journey_at_stops }

    it 'should add errors a stop departure_time is greater then next stop arrival time' do
      vjas[0][:departure_time] = vjas[1][:arrival_time] + 1.minute
      vehicle_journey.validate

      expect(vjas[0].errors[:departure_time]).not_to be_blank
      expect(vehicle_journey.errors.count).to eq(1)
      expect(vehicle_journey).not_to be_valid
    end

    it 'should consider valid to have departure_time equal to next stop arrival time' do
      vjas[0][:departure_time] = vjas[1][:arrival_time]
      vehicle_journey.validate

      expect(vjas[0].errors[:departure_time]).to be_blank
      expect(vehicle_journey.errors).to be_empty
      expect(vehicle_journey).to be_valid
    end

    it 'should not add errors when departure_time is less then next stop arrival time' do
      vehicle_journey.validate
      vjas.each do |stop|
        expect(stop.errors).to be_empty
      end
      expect(vehicle_journey).to be_valid
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

    def vehicle_journey_to_state vj
      vj.slice('objectid', 'published_journey_name', 'journey_pattern_id', 'company_id').tap do |item|
        item['vehicle_journey_at_stops'] = []
        item['time_tables']              = []
        item['purchase_windows']         = []
        item['footnotes']                = []
        item['purchase_windows']         = []
        item['custom_fields']            = vj.custom_fields.to_hash

        vj.vehicle_journey_at_stops.each do |vjas|
          item['vehicle_journey_at_stops'] << vehicle_journey_at_stop_to_state(vjas)
        end
      end
    end

    let(:route)           { create :route }
    let(:journey_pattern) { create :journey_pattern, route: route }
    let(:vehicle_journey) { create :vehicle_journey, route: route, journey_pattern: journey_pattern }
    let(:state)           { vehicle_journey_to_state(vehicle_journey) }
    let(:collection)      { [state] }

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
      obj.run_callbacks(:commit)

      expect(collection.last['objectid']).to eq obj.objectid
      expect(obj.published_journey_name).to eq 'dummy'
      expect(obj.custom_fields["energy"].value).to eq 99
    end

    it 'should expect local times' do
      new_vj = build(:vehicle_journey, objectid: nil, published_journey_name: 'dummy', route: route, journey_pattern: journey_pattern)
      stop_area = create(:stop_area, time_zone: "Mexico City")
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

    it 'should not save vehicle_journey_at_stops of newly created vj if all departure time is set to 00:00' do
      new_vj = build(:vehicle_journey, objectid: nil, published_journey_name: 'dummy', route: route, journey_pattern: journey_pattern)
      2.times do
        new_vj.vehicle_journey_at_stops << build(:vehicle_journey_at_stop,
                   :vehicle_journey => new_vj,
                   :stop_point      => create(:stop_point),
                   :arrival_time    => '2000-01-01 00:00:00 UTC',
                   :departure_time  => '2000-01-01 00:00:00 UTC')
      end
      collection << vehicle_journey_to_state(new_vj)
      expect {
        Chouette::VehicleJourney.state_update(route, collection)
      }.not_to change {Chouette::VehicleJourneyAtStop.count}
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

    it 'should clear vj time_tableas association when remove from state' do
      vehicle_journey.time_tables << create(:time_table)
      state['time_tables'] = []
      vehicle_journey.update_has_and_belongs_to_many_from_state(state)

      expect(vehicle_journey.reload.time_tables).to be_empty
    end

    it 'should update vj purchase_windows association from state' do
      2.times{state['purchase_windows'] << create(:purchase_window, referential: referential).slice('id', 'name', 'objectid', 'color')}
      vehicle_journey.update_has_and_belongs_to_many_from_state(state)

      expected = state['purchase_windows'].map{|tt| tt['id']}
      actual   = vehicle_journey.reload.purchase_windows.map(&:id)
      expect(actual).to match_array(expected)
    end

    it 'should clear vj purchase_windows association when remove from state' do
      vehicle_journey.purchase_windows << create(:purchase_window, referential: referential)
      state['purchase_windows'] = []
      vehicle_journey.update_has_and_belongs_to_many_from_state(state)

      expect(vehicle_journey.reload.purchase_windows).to be_empty
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
end
