
RSpec.describe CleanUp, :type => :model do

  # it { should validate_presence_of(:begin_date).with_message(:presence) }
  it { should belong_to(:referential) }

  context 'Clean Up With Date Type : Between' do
    subject(:cleaner) { create(:clean_up, date_type: :between) }
    it { should validate_presence_of(:end_date).with_message(:presence) }

    it 'should have a end date strictly greater than the begin date' do
      expect(cleaner).to be_valid

      cleaner.end_date = cleaner.begin_date
      expect(cleaner).not_to be_valid
    end
  end

  context 'Clean Up With Date Type : Outside' do
    subject(:cleaner) { create(:clean_up, date_type: :outside) }
    it { should validate_presence_of(:end_date).with_message(:presence) }

    it 'should have a end date strictly greater than the begin date' do
      expect(cleaner).to be_valid

      cleaner.end_date = cleaner.begin_date
      expect(cleaner).not_to be_valid
    end
  end

  describe '#worker_died' do
    subject(:cleaner) { create(:clean_up, date_type: :outside) }

    it 'should set merge status to failed' do
      expect(cleaner.status).to eq("new")
      cleaner.worker_died
      expect(cleaner.status).to eq("failed")
    end
  end

  context '#clean' do
    let(:referential) { Referential.new prefix: "prefix"}
    let(:cleaner) { create(:clean_up, date_type: :before, referential: referential) }

    before do
      allow(referential).to receive(:switch)
    end

    it 'should call cleanup methods' do
      expect(cleaner).to receive(:clean_time_tables)
      expect(cleaner).to receive(:clean_time_table_dates)
      expect(cleaner).to receive(:clean_time_table_periods)
      cleaner.clean
    end

    it "should set the referential state to the original_state value" do
      cleaner.original_state = :archived
      expect(cleaner.referential).to receive :archived!
      cleaner.clean
    end
  end

  context 'timetables related cleanings' do
    let(:cleaner) { create(:clean_up, date_type: date_type, begin_date: begin_date, end_date: end_date) }
    let(:end_date){ nil }
    let(:begin_date) { '01/01/2010'.to_date }

    context '#clean_time_tables' do
      let!(:time_table) { create(:time_table, start_date: begin_date + 1.day) }
      let!(:before_time_table) { create(:time_table, start_date: begin_date - 10.years ) }
      context 'before' do
        let(:date_type){ :before }
        it 'should destroy timetables before begin_date' do
          expect{ cleaner.clean_time_tables }.to change{ Chouette::TimeTable.count }.by -1
          expect{ time_table.reload }.to_not raise_error
          expect{ before_time_table.reload }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'after' do
        let(:date_type){ :after }
        it 'should destroy timetables after begin_date' do
          expect{ cleaner.clean_time_tables }.to change{ Chouette::TimeTable.count }.by -1
          expect{ time_table.reload }.to raise_error ActiveRecord::RecordNotFound
          expect{ before_time_table.reload }.to_not raise_error
        end

        it 'should destroy time_table <> vehicle_journey association' do
          vj = create(:vehicle_journey, time_tables: [time_table, create(:time_table, start_date: 10.years.ago)])
          cleaner.clean_time_tables

          expect(vj.reload.time_tables.map(&:id)).to_not include(time_table.id)
        end
      end

      context 'between' do
        let(:date_type){ :between }
        let(:end_date){ time_table.end_date }
        let!(:shorter_time_table) { create(:time_table, start_date: begin_date + 1.day, periods_count: 1 ) }

        it 'should destroy timetables between dates' do
          expect{ cleaner.clean_time_tables }.to change{ Chouette::TimeTable.count }.by -1
          expect{ time_table.reload }.to_not raise_error
          expect{ before_time_table.reload }.to_not raise_error
          expect{ shorter_time_table.reload }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'outside' do
        let(:date_type){ :outside }
        let(:end_date){ time_table.end_date }
        let!(:shorter_time_table) { create(:time_table, start_date: begin_date + 1.day, periods_count: 1 ) }
        let!(:after_time_table) { create(:time_table, start_date: begin_date + 1.year ) }

        it 'should destroy timetables outside dates' do
          expect{ cleaner.clean_time_tables }.to change{ Chouette::TimeTable.count }.by -2
          expect{ time_table.reload }.to_not raise_error
          expect{ before_time_table.reload }.to raise_error ActiveRecord::RecordNotFound
          expect{ after_time_table.reload }.to raise_error ActiveRecord::RecordNotFound
          expect{ shorter_time_table.reload }.to_not raise_error
        end
      end
    end

    context '#clean_time_table_dates' do
      before(:each) { Chouette::TimeTableDate.delete_all }

      let(:time_table) { create :time_table, dates_count: 0 }
      let!(:before_date) { create :time_table_date, date: begin_date - 1.day, in_out: true, time_table: time_table }
      let!(:after_date) { create :time_table_date, date: begin_date + 1.day, in_out: true, time_table: time_table }

      context 'before' do
        let(:date_type){ :before }

        it 'should destroy dates before begin_date' do
          expect{ cleaner.clean_time_table_dates }.to change{ Chouette::TimeTableDate.count }.by -1
          expect{ after_date.reload }.to_not raise_error
          expect{ before_date.reload }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'after' do
        let(:date_type){ :after }

        it 'should destroy dates after begin_date' do
          expect{ cleaner.clean_time_table_dates }.to change{ Chouette::TimeTableDate.count }.by -1
          expect{ after_date.reload }.to raise_error ActiveRecord::RecordNotFound
          expect{ before_date.reload }.to_not raise_error
        end
      end

      context 'between' do
        let(:date_type){ :between }
        let(:end_date){ begin_date + 2.day }

        it 'should destroy dates between dates' do
          expect{ cleaner.clean_time_table_dates }.to change{ Chouette::TimeTableDate.count }.by -1
          expect{ after_date.reload }.to raise_error ActiveRecord::RecordNotFound
          expect{ before_date.reload }.to_not raise_error
        end
      end

      context 'outside' do
        let(:date_type){ :outside }
        let(:end_date){ begin_date + 2.day }

        it 'should destroy dates outside dates' do
          expect{ cleaner.clean_time_table_dates }.to change{ Chouette::TimeTableDate.count }.by -1
          expect{ after_date.reload }.to_not raise_error
          expect{ before_date.reload }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    context '#clean_time_table_periods' do
      let(:time_table) { create :time_table, :empty }

      context 'before' do
        let(:date_type){ :before }
        it 'should destroy periods before begin_date' do
          period = time_table.periods.create(period_start: begin_date - 10.days, period_end: begin_date + 10.day)
          expect{ cleaner.clean_time_table_periods }.to change{ period.reload.period_start }.from(begin_date - 10.days).to(begin_date)
        end

        it 'create dates when remaining period is too short' do
          time_table.periods.create(period_start: begin_date - 10.days, period_end: begin_date)
          expect{ cleaner.clean_time_table_periods }.to change{ Chouette::TimeTableDate.count }.by 1
          expect(Chouette::TimeTableDate.last.date).to eq begin_date
        end
      end

      context 'after' do
        let(:date_type){ :after }

        it 'should truncate periods' do
          period = time_table.periods.create(period_start: begin_date - 10.days, period_end: begin_date + 10.day)
          expect{ cleaner.clean_time_table_periods }.to change{ period.reload.period_end }.from(begin_date + 10.days).to(begin_date)
        end

        it 'create dates when remaining period is too short' do
          time_table.periods.create(period_start: begin_date, period_end: begin_date + 10.days)
          expect{ cleaner.clean_time_table_periods }.to change{ Chouette::TimeTableDate.count }.by 1
          expect(Chouette::TimeTableDate.last.date).to eq begin_date
        end
      end

      context 'between' do
        let(:date_type){ :between }
        let(:end_date){ begin_date + 2.day }

        it 'should truncate periods' do
          period = time_table.periods.create(period_start: begin_date - 10.days, period_end: begin_date + 1.day)
          cleaner.clean_time_table_periods
          expect(period.reload.period_start).to eq(begin_date - 10.days)
          expect(period.reload.period_end).to eq(begin_date - 1.day)
        end

        it 'create dates when remaining period is too short' do
          time_table.periods.create(period_start: begin_date - 1.day, period_end: begin_date)
          expect{ cleaner.clean_time_table_periods }.to change{ Chouette::TimeTableDate.count }.by 1
          expect(Chouette::TimeTableDate.last.date).to eq begin_date - 1.day
        end
      end

      context 'outside' do
        let(:date_type){ :outside }
        let(:end_date){ begin_date + 2.day }

        it 'should truncate periods' do
          period = time_table.periods.create(period_start: begin_date - 10.days, period_end: begin_date + 10.day)
          cleaner.clean_time_table_periods
          expect(period.reload.period_start).to eq(begin_date)
          expect(period.reload.period_end).to eq(end_date)
        end

        it 'create dates when remaining period is too short' do
          time_table.periods.create(period_start: begin_date - 10, period_end: begin_date)
          expect{cleaner.clean_time_table_periods}.to change{ Chouette::TimeTableDate.count }.by 1
          expect(Chouette::TimeTableDate.last.date).to eq begin_date
        end
      end
    end
  end

  context '#clean' do
    let(:data_cleanups) { [] }
    let(:cleaner) { create(:clean_up, date_type: :after, begin_date: begin_date, end_date: end_date, data_cleanups: data_cleanups ) }
    let(:end_date){ nil }
    let(:begin_date) { '01/01/2010'.to_date }

    it 'should not call any data_cleanup method' do
      CleanUp.data_cleanups.values.each do |meth|
        expect(cleaner).to_not receive meth
      end
      cleaner.clean
    end

    context 'with an extra data_cleanup' do
      let(:data_cleanups) { [CleanUp.data_cleanups.values.first] }

      it 'should call only one data_cleanup method' do
        (CleanUp.data_cleanups.values - data_cleanups).each do |meth|
          expect(cleaner).to_not receive meth
        end
        data_cleanups.each do |meth|
          expect(cleaner).to receive meth
        end
        cleaner.clean
      end
    end
  end

  ########
  ########
  ########
  ########

  context '#clean_vehicle_journeys_without_time_table' do
    let(:cleaner) { create(:clean_up) }

    it 'should destroy vehicle_journey' do
      vj = create(:vehicle_journey)
      expect{cleaner.clean_vehicle_journeys_without_time_table
      }.to change { Chouette::VehicleJourney.count }.by(-1)
    end

    it 'should not destroy vehicle_journey with time_table' do
      create(:vehicle_journey, time_tables: [create(:time_table)])
      expect{cleaner.clean_vehicle_journeys_without_time_table
      }.to_not change { Chouette::VehicleJourney.count }
    end
  end

  describe "#clean_routes_outside_referential" do
    let(:line_referential) { create(:line_referential) }
    let(:line) { create(:line, line_referential: line_referential) }
    let(:metadata) { create(:referential_metadata, lines: [line]) }
    let(:referential) { create(:workbench_referential, metadatas: [metadata]) }
    let(:cleaner) { create(:clean_up, referential: referential) }

    it "destroys routes not in the the referential" do
      route = create :route
      opposite = create :route, line: route.line, opposite_route: route, wayback: route.opposite_wayback

      cleaner.clean_routes_outside_referential

      expect(Chouette::Route.exists?(route.id)).to be false

      line.routes.each do |route|
        expect(route).not_to be_destroyed
      end
    end

    it "cascades destruction of vehicle journeys and journey patterns" do
      vehicle_journey = create(:vehicle_journey)

      cleaner.clean_routes_outside_referential

      expect(Chouette::Route.exists?(vehicle_journey.route.id)).to be false
      expect(
        Chouette::JourneyPattern.exists?(vehicle_journey.journey_pattern.id)
      ).to be false
      expect(Chouette::VehicleJourney.exists?(vehicle_journey.id)).to be false
    end

    it "removes join tables rows" do
      class TimeTablesVehicleJourney < ActiveRecord::Base; end
      class FootnotesVehicleJourney < ActiveRecord::Base; end
      class JourneyPatternStopPoint < ActiveRecord::Base; end

      vehicle_journey = create(:vehicle_journey)
      footnote  = create(:footnote)
      time_table  = create(:time_table)
      vehicle_journey.time_tables << time_table
      vehicle_journey.footnotes << footnote

      expect(TimeTablesVehicleJourney.where(vehicle_journey_id: vehicle_journey.id)).to be_exists
      expect(FootnotesVehicleJourney.where(vehicle_journey_id: vehicle_journey.id)).to be_exists
      expect(JourneyPatternStopPoint.where(journey_pattern_id: vehicle_journey.journey_pattern_id)).to be_exists

      cleaner.clean_routes_outside_referential
      expect(TimeTablesVehicleJourney.where(vehicle_journey_id: vehicle_journey.id)).to_not be_exists
      expect(FootnotesVehicleJourney.where(vehicle_journey_id: vehicle_journey.id)).to_not be_exists
      expect(JourneyPatternStopPoint.where(journey_pattern_id: vehicle_journey.journey_pattern_id)).to_not be_exists
    end
  end

  describe "#clean_unassociated_footnotes" do
    let(:cleaner) { create(:clean_up) }
    it "should destroy all footnotes that are not associated with a vehicle joruney" do
      footnote = create(:footnote)
      expect{cleaner.clean_unassociated_footnotes
      }.to change { Chouette::Footnote.count }.by(-1)
    end

    it "should not destroy all footnotes that are associated with a vehicle joruney" do
      vj = create(:vehicle_journey)
      vj.footnotes << create(:footnote)
      expect{cleaner.clean_unassociated_footnotes
      }.to_not change { Chouette::Footnote.count }
    end
  end

  describe "#clean_unassociated_calendars" do
    let(:cleaner) { create(:clean_up) }
    it "should destroy all time_tables that are not associated with a vehicle joruney" do
      tt = create(:time_table)

      cleaner.clean_unassociated_calendars

      expect(Chouette::TimeTable.exists?(tt.id)).to be false
    end


    it "should not destroy time_tables that are associated with a vehicle joruney" do
      vj = create(:vehicle_journey)
      tt = create(:time_table)

      vj.time_tables << tt

      cleaner.clean_unassociated_calendars

      expect(Chouette::TimeTable.exists?(tt.id)).to be true
    end
  end

  describe "#clean_irrelevant_data" do
    it "calls the appropriate destroy methods" do
      cleaner = create(:clean_up)

      expect(cleaner).to receive(:clean_unassociated_vehicle_journeys)
      expect(cleaner).to receive(:clean_unassociated_journey_patterns)
      expect(cleaner).to receive(:clean_unassociated_routes)
      expect(cleaner).to receive(:clean_unassociated_footnotes)

      cleaner.clean_irrelevant_data
    end
  end

  describe "#run_methods" do
    let(:cleaner) { create(:clean_up) }

    it "calls methods in the :clean_methods attribute" do
      cleaner = build(
        :clean_up,
        clean_methods: [:clean_routes_outside_referential]
      )

      expect(cleaner).to receive(:clean_routes_outside_referential)
      cleaner.run_methods
    end

    it "doesn't do anything if :clean_methods is nil" do
      cleaner = create(:clean_up)

      expect { cleaner.run_methods }.not_to raise_error
    end
  end
end
