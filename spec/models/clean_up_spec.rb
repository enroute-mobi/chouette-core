require 'rails_helper'

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

  context '#exclude_dates_in_overlapping_period with :before date_type' do
    let(:time_table) { create(:time_table) }
    let(:period) { time_table.periods[0] }
    let(:cleaner) { create(:clean_up, date_type: :before, begin_date: period.period_end) }

    it 'should add exclude date into period for overlapping period' do
      days_in_period = (period.period_start..period.period_end).count

      expect { cleaner.exclude_dates_in_overlapping_period(period) }.to change {
        time_table.dates.where(in_out: false).count
      }.by(days_in_period - 1)
    end

    it 'should not add exclude date if no overlapping found' do
      cleaner.begin_date = period.period_start
      expect { cleaner.exclude_dates_in_overlapping_period(period) }.to_not change {
        time_table.dates.where(in_out: false).count
      }
    end
  end

  context '#exclude_dates_in_overlapping_period with :after date_type' do
    let(:time_table) { create(:time_table) }
    let(:period) { time_table.periods[0] }
    let(:cleaner) { create(:clean_up, date_type: :after, begin_date: period.period_start + 1.day) }

    it 'should add exclude date into period for overlapping period' do
      days_in_period = (period.period_start..period.period_end).count
      expect { cleaner.exclude_dates_in_overlapping_period(period) }.to change {
        time_table.dates.where(in_out: false).count
      }.by(days_in_period - 2)
    end

    it 'should not add exclude date if no overlapping found' do
      cleaner.begin_date = period.period_end
      expect { cleaner.exclude_dates_in_overlapping_period(period) }.to_not change {
        time_table.dates.where(in_out: false).count
      }
    end
  end

   context '#exclude_dates_in_overlapping_period with :between date_type' do
    let(:time_table) { create(:time_table) }
    let(:period) { time_table.periods[0] }
    let(:cleaner) { create(:clean_up, date_type: :between, begin_date: period.period_start + 3.day, end_date: period.period_end) }

    it 'should add exclude date into period for overlapping period' do

      expected_day_out = (cleaner.begin_date..cleaner.end_date).count
      expect { cleaner.exclude_dates_in_overlapping_period(period) }.to change {
        time_table.dates.where(in_out: false).count
      }.by(expected_day_out - 2)
    end

    it 'should not add exclude date if no overlapping found' do
      cleaner.begin_date = period.period_end  + 1.day
      cleaner.end_date   = cleaner.begin_date + 1.day

      expect { cleaner.exclude_dates_in_overlapping_period(period) }.to_not change {
        time_table.dates.where(in_out: false).count
      }
    end
  end

  context '#overlapping_periods' do
    let(:time_table) { create(:time_table) }
    let(:period) { time_table.periods[0] }
    let(:cleaner) { create(:clean_up, date_type: :before, begin_date: period.period_start) }

    it 'should detect overlapping periods' do
      expect(cleaner.overlapping_periods).to include(time_table.periods[0])
    end

    it 'should not return none overlapping periods' do
      cleaner.begin_date = time_table.periods[0].period_start - 1.day
      expect(cleaner.overlapping_periods).to_not include(time_table.periods[0])
    end
  end

  context '#clean' do
    let(:referential) { Referential.new prefix: "prefix"}
    let(:cleaner) { create(:clean_up, date_type: :before, referential: referential) }

    before do
      allow(referential).to receive(:switch)
    end


    it 'should call destroy_time_tables_before' do
      cleaner.date_type = :before
      expect(cleaner).to receive(:destroy_time_tables_before)
      expect(cleaner).to receive(:destroy_time_tables_dates_before)
      expect(cleaner).to receive(:destroy_time_tables_periods_before)
      cleaner.clean
    end

    it 'should call destroy_time_tables_after' do
      cleaner.date_type = :after
      expect(cleaner).to receive(:destroy_time_tables_after)
      expect(cleaner).to receive(:destroy_time_tables_dates_after)
      expect(cleaner).to receive(:destroy_time_tables_periods_after)
      cleaner.clean
    end

    it 'should call destroy_time_tables_between' do
      cleaner.date_type = :between
      expect(cleaner).to receive(:destroy_time_tables_between)
      expect(cleaner).to receive(:destroy_time_tables_dates_between)
      expect(cleaner).to receive(:destroy_time_tables_periods_between)
      cleaner.clean
    end

    it "should set the referential state to the original_state value" do
      cleaner.original_state = :archived
      expect(cleaner.referential).to receive :archived!
      cleaner.clean
    end
  end

  context '#destroy_time_tables_dates_between' do
    let!(:time_table) { create(:time_table) }
    let(:cleaner) { create(:clean_up, date_type: :between) }

    before do
      time_table.periods.clear
      time_table.save
      cleaner.begin_date = time_table.start_date
      cleaner.end_date   = time_table.end_date
    end

    it 'should destroy record' do
      expect{ cleaner.destroy_time_tables_dates_between }.to change {
        Chouette::TimeTableDate.count
      }.by(-time_table.dates.count + 2)
    end

    it 'should not destroy record not in range' do
      cleaner.begin_date = time_table.end_date + 1.day
      cleaner.end_date   = cleaner.begin_date + 1.day

      expect{ cleaner.destroy_time_tables_dates_between }.to_not change {
        Chouette::TimeTableDate.count
      }
    end
  end

  context '#destroy_time_tables_dates_after' do
    let!(:time_table_date) { create(:time_table_date, date: Date.yesterday, in_out: true) }
    let(:cleaner) { create(:clean_up, date_type: :after, begin_date: time_table_date.date) }

    it 'should destroy record' do
      count = Chouette::TimeTableDate.where('date > ?', cleaner.begin_date).count
      expect{ cleaner.destroy_time_tables_dates_after }.to change {
        Chouette::TimeTableDate.count
      }.by(-count)
    end
  end

  context '#destroy_time_tables_between' do
    let!(:time_table) { create(:time_table ) }
    let(:cleaner) { create(:clean_up, date_type: :between, begin_date: time_table.start_date - 1.day, end_date: time_table.end_date + 1.day) }

    it 'should destroy time_tables with validity period in purge range' do
      expect{ cleaner.destroy_time_tables_between }.to change {
        Chouette::TimeTable.count
      }.by(-1)
    end

    it 'should not destroy time_tables if not totaly inside purge range' do
      cleaner.begin_date = time_table.start_date + 1.day
      expect{ cleaner.destroy_time_tables_between }.to_not change {
        Chouette::TimeTable.count
      }
    end
  end

  context '#destroy_time_tables_after' do
    let!(:time_table) { create(:time_table ) }
    let(:cleaner) { create(:clean_up, date_type: :after, begin_date: time_table.start_date - 1.day) }

    it 'should destroy time_tables with start_date > purge begin_date' do
      expect{ cleaner.destroy_time_tables_after }.to change {
        Chouette::TimeTable.count
      }.by(-1)
    end

    it 'should not destroy time_tables with start_date < purge begin date' do
      cleaner.begin_date = time_table.end_date
      expect{ cleaner.destroy_time_tables_after }.to_not change {
        Chouette::TimeTable.count
      }
    end
  end

  context '#destroy_time_tables' do
    let!(:time_table) { create(:time_table) }
    let(:cleaner) { create(:clean_up) }

    it 'should destroy all time_tables' do
      expect{cleaner.destroy_time_tables(Chouette::TimeTable.all)}.to change {
        Chouette::TimeTable.count
      }.by(-1)
    end

    it 'should destroy time_table vehicle_journey association' do
      vj = create(:vehicle_journey, time_tables: [time_table, create(:time_table)])
      cleaner.destroy_time_tables(Chouette::TimeTable.where(id: time_table.id))

      expect(vj.reload.time_tables.map(&:id)).to_not include(time_table.id)
    end

    it 'should also destroy associated vehicle_journey if it belongs to any other time_table' do
      vj = create(:vehicle_journey, time_tables: [time_table])
      expect{cleaner.destroy_time_tables(Chouette::TimeTable.all)}.to change {
        Chouette::VehicleJourney.count
      }.by(-1)
    end
  end

  context '#destroy_vehicle_journey_without_time_table' do
    let(:cleaner) { create(:clean_up) }

    it 'should destroy vehicle_journey' do
      vj = create(:vehicle_journey)
      expect{cleaner.destroy_vehicle_journey_without_time_table
      }.to change { Chouette::VehicleJourney.count }.by(-1)
    end

    it 'should not destroy vehicle_journey with time_table' do
      create(:vehicle_journey, time_tables: [create(:time_table)])
      expect{cleaner.destroy_vehicle_journey_without_time_table
      }.to_not change { Chouette::VehicleJourney.count }
    end
  end

  context '#destroy_time_tables_before' do
    let!(:time_table) { create(:time_table ) }
    let(:cleaner) { create(:clean_up, date_type: :before, begin_date: time_table.end_date + 1.day) }

    it 'should destroy time_tables with end_date < purge begin_date' do
      expect{ cleaner.destroy_time_tables_before }.to change {
        Chouette::TimeTable.count
      }.by(-1)
    end

    it 'should not destroy time_tables with end_date > purge begin_date' do
      cleaner.begin_date = Date.today
      expect{ cleaner.destroy_time_tables_before }.to_not change {
        Chouette::TimeTable.count
      }
    end
  end

  describe "#destroy_routes_outside_referential" do
    let(:line_referential) { create(:line_referential) }
    let(:line) { create(:line, line_referential: line_referential) }
    let(:metadata) { create(:referential_metadata, lines: [line]) }
    let(:referential) { create(:workbench_referential, metadatas: [metadata]) }
    let(:cleaner) { create(:clean_up, referential: referential) }

    it "destroys routes not in the the referential" do
      route = create :route
      opposite = create :route, line: route.line, opposite_route: route, wayback: route.opposite_wayback

      cleaner.destroy_routes_outside_referential

      expect(Chouette::Route.exists?(route.id)).to be false

      line.routes.each do |route|
        expect(route).not_to be_destroyed
      end
    end

    it "cascades destruction of vehicle journeys and journey patterns" do
      vehicle_journey = create(:vehicle_journey)

      cleaner.destroy_routes_outside_referential

      expect(Chouette::Route.exists?(vehicle_journey.route.id)).to be false
      expect(
        Chouette::JourneyPattern.exists?(vehicle_journey.journey_pattern.id)
      ).to be false
      expect(Chouette::VehicleJourney.exists?(vehicle_journey.id)).to be false
    end

    it "removes join tables rows" do
      class PurchaseWindowsVehicleJourney < ActiveRecord::Base; end
      class TimeTablesVehicleJourney < ActiveRecord::Base; end
      class FootnotesVehicleJourney < ActiveRecord::Base; end
      class JourneyPatternsStopPoint < ActiveRecord::Base; end

      vehicle_journey = create(:vehicle_journey)
      purchase_window  = create(:purchase_window)
      footnote  = create(:footnote)
      time_table  = create(:time_table)
      vehicle_journey.purchase_windows << purchase_window
      vehicle_journey.time_tables << time_table
      vehicle_journey.footnotes << footnote

      expect(PurchaseWindowsVehicleJourney.where(vehicle_journey_id: vehicle_journey.id)).to be_exists
      expect(TimeTablesVehicleJourney.where(vehicle_journey_id: vehicle_journey.id)).to be_exists
      expect(FootnotesVehicleJourney.where(vehicle_journey_id: vehicle_journey.id)).to be_exists
      expect(JourneyPatternsStopPoint.where(journey_pattern_id: vehicle_journey.journey_pattern_id)).to be_exists

      cleaner.destroy_routes_outside_referential
      expect(PurchaseWindowsVehicleJourney.where(vehicle_journey_id: vehicle_journey.id)).to_not be_exists
      expect(TimeTablesVehicleJourney.where(vehicle_journey_id: vehicle_journey.id)).to_not be_exists
      expect(FootnotesVehicleJourney.where(vehicle_journey_id: vehicle_journey.id)).to_not be_exists
      expect(JourneyPatternsStopPoint.where(journey_pattern_id: vehicle_journey.journey_pattern_id)).to_not be_exists
    end
  end

  describe "#destroy_unassociated_footnotes" do
    let(:cleaner) { create(:clean_up) }
    it "should destroy all footnotes that are not associated with a vehicle joruney" do
      footnote = create(:footnote)
      expect{cleaner.destroy_unassociated_footnotes
      }.to change { Chouette::Footnote.count }.by(-1)
    end

    it "should not destroy all footnotes that are associated with a vehicle joruney" do
      vj = create(:vehicle_journey)
      vj.footnotes << create(:footnote)
      expect{cleaner.destroy_unassociated_footnotes
      }.to_not change { Chouette::Footnote.count }
    end
  end

  describe "#destroy_unassociated_calendars" do
    let(:cleaner) { create(:clean_up) }
    it "should destroy all time_tables that are not associated with a vehicle joruney" do
      tt = create(:time_table)
      pw = create(:purchase_window)

      cleaner.destroy_unassociated_calendars

      expect(Chouette::TimeTable.exists?(tt.id)).to be false
      expect(Chouette::PurchaseWindow.exists?(pw.id)).to be false
    end


    it "should not destroy time_tables nor purchase windows that are associated with a vehicle joruney" do
      vj = create(:vehicle_journey)
      tt = create(:time_table)
      pw = create(:purchase_window)

      vj.time_tables << tt
      vj.purchase_windows << pw

      cleaner.destroy_unassociated_calendars

      expect(Chouette::TimeTable.exists?(tt.id)).to be true
      expect(Chouette::PurchaseWindow.exists?(pw.id)).to be true
    end
  end

  describe "#destroy_empty" do
    it "calls the appropriate destroy methods" do
      cleaner = create(:clean_up)

      expect(cleaner).to receive(:destroy_vehicle_journeys)
      expect(cleaner).to receive(:destroy_journey_patterns)
      expect(cleaner).to receive(:destroy_routes)
      expect(cleaner).to receive(:destroy_unassociated_footnotes)

      cleaner.destroy_empty
    end
  end

  describe "#run_methods" do
    let(:cleaner) { create(:clean_up) }

    it "calls methods in the :methods attribute" do
      cleaner = create(
        :clean_up,
        methods: [:destroy_routes_outside_referential]
      )

      expect(cleaner).to receive(:destroy_routes_outside_referential)
      cleaner.run_methods
    end

    it "doesn't do anything if :methods is nil" do
      cleaner = create(:clean_up)

      expect { cleaner.run_methods }.not_to raise_error
    end
  end
end
