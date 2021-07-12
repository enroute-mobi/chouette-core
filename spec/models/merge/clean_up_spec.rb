RSpec.describe Merge do
  let(:context) do
    Chouette.create do
      referential periods: [ 1.month.ago.to_date..1.month.from_now.to_date ] do
        time_table :old_timetable, periods: [ 1.month.ago.to_date..Time.zone.today-5 ]
        time_table :previous_timetable, periods: [ 1.month.ago.to_date..Time.zone.today ]
        time_table :new_timetable

        vehicle_journey :old_vehicle_journey, time_tables: [ :old_timetable ]
        vehicle_journey :previous_vehicle_journey, time_tables: [ :previous_timetable ]
        vehicle_journey time_tables: [ :old_timetable, :new_timetable ]
        vehicle_journey :new_vehicle_journey, time_tables: [ :new_timetable ]
      end
    end
  end
  let(:workbench) { context.workbench }
  let(:workgroup) { context.workgroup }
  let(:merge) do
    Merge.new created_at: Time.now, workbench: workbench, referentials: [context.referential]
  end

  let(:old_timetable) { context.time_table :old_timetable }
  let(:old_vehicle_journey) { context.vehicle_journey :old_vehicle_journey }

  let(:previous_timetable) { context.time_table :previous_timetable }
  let(:previous_vehicle_journey) { context.vehicle_journey :previous_vehicle_journey }

  let(:new_timetable) { context.time_table :new_timetable }
  let(:new_vehicle_journey) { context.vehicle_journey :new_vehicle_journey }

  context "when the workgroup has the option 'enable_purge_merged_data'" do
    before { workgroup.update enable_purge_merged_data: true }

    context 'after merge' do
      before { workgroup.update maximum_data_age: maximum_age }
      before { merge.merge! }

      context 'when maximum age is zero' do
        let(:maximum_age) { 0 }

        it 'cleans an old TimeTable' do
          expect(old_timetable).to_not exist_in_database
        end

        it 'cleans an old Vehicle Journey' do
          expect(old_vehicle_journey).to_not exist_in_database
        end

        it 'keeps a previous TimeTable (ending today)' do
          expect(previous_timetable).to exist_in_database
        end

        it 'keeps a previous Vehicle Journey (ending today)' do
          expect(previous_vehicle_journey).to exist_in_database
        end

        it 'keeps a new TimeTable' do
          expect(new_timetable).to exist_in_database
        end

        it 'keeps a new Vehicle Journey' do
          expect(new_vehicle_journey).to exist_in_database
        end

        it 'removes/truncates metadatas before today' do
          expect(merge.new.validity_period.begin).to eq(Time.zone.today)
        end
      end

      context 'when the maximum age is 3 days' do
        let(:maximum_age) { 3 }

        it 'cleans an old TimeTable' do
          expect(old_timetable).to_not exist_in_database
        end

        it 'cleans an old Vehicle Journey' do
          expect(old_vehicle_journey).to_not exist_in_database
        end

        it 'keeps an previous TimeTable (ending today)' do
          expect(previous_timetable).to exist_in_database
        end

        it 'keeps an previous Vehicle Journey (ending today)' do
          expect(previous_vehicle_journey).to exist_in_database
        end

        it 'keeps a new TimeTable' do
          expect(new_timetable).to exist_in_database
        end

        it 'keeps a new Vehicle Journey' do
          expect(new_vehicle_journey).to exist_in_database
        end

        it 'removes/truncates metadatas before 3 days' do
          expect(merge.new.validity_period.begin).to eq(Time.zone.today - maximum_age)
        end
      end

      context 'when maximum age is older than the old timetable' do
        let(:maximum_age) { 5 }

        it 'keeps an old TimeTable' do
          expect(old_timetable).to exist_in_database
        end

        it 'keeps an old Vehicle Journey' do
          expect(old_vehicle_journey).to exist_in_database
        end

        it 'keeps an previous TimeTable (ending today)' do
          expect(previous_timetable).to exist_in_database
        end

        it 'keeps an previous Vehicle Journey (ending today)' do
          expect(previous_vehicle_journey).to exist_in_database
        end

        it 'keeps a new TimeTable' do
          expect(new_timetable).to exist_in_database
        end

        it 'keeps a new Vehicle Journey' do
          expect(new_vehicle_journey).to exist_in_database
        end

        it 'removes/truncates metadatas before 5 days' do
          expect(merge.new.validity_period.begin).to eq(Time.zone.today - maximum_age)
        end
      end
    end
  end

  context "when the workgroup hasn't the option 'enable_purge_merged_data'" do
    before { workgroup.update enable_purge_merged_data: false }
    before { merge.merge! }

    it 'keeps an old TimeTable' do
      expect(old_timetable).to exist_in_database
    end

    it 'keeps an old Vehicle Journey' do
      expect(old_vehicle_journey).to exist_in_database
    end

    it 'keeps an previous TimeTable (ending today)' do
      expect(previous_timetable).to exist_in_database
    end

    it 'keeps an previous Vehicle Journey (ending today)' do
      expect(previous_vehicle_journey).to exist_in_database
    end

    it 'keeps a new TimeTable' do
      expect(new_timetable).to exist_in_database
    end

    it 'keeps a new Vehicle Journey' do
      expect(new_vehicle_journey).to exist_in_database
    end

    it 'leaves unchanged metadatas' do
      expect(merge.new.validity_period.begin).to eq(1.month.ago.to_date)
    end
  end

end
