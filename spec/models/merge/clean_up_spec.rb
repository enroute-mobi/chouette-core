# frozen_string_literal: true

RSpec.describe Merge do
  let(:context) do
    Chouette.create do
      referential periods: [1.month.ago.to_date..1.month.from_now.to_date] do
        time_table :old_timetable, comment: 'Old', periods: [1.month.ago.to_date..Time.zone.today - 5]
        time_table :previous_timetable, comment: 'Previous', periods: [1.month.ago.to_date..Time.zone.today]
        time_table :new_timetable, comment: 'New'

        vehicle_journey :old_vehicle_journey, published_journey_name: 'Old', time_tables: [:old_timetable]
        vehicle_journey :previous_vehicle_journey, published_journey_name: 'Previous',
                                                   time_tables: [:previous_timetable]
        vehicle_journey time_tables: %i[old_timetable new_timetable]
        vehicle_journey :new_vehicle_journey, published_journey_name: 'New', time_tables: [:new_timetable]
      end
    end
  end
  let(:workbench) { context.workbench }
  let(:workgroup) { context.workgroup }
  let(:merge) do
    Merge.new created_at: Time.zone.now, workbench: workbench, referentials: [context.referential]
  end

  let(:referential) { merge.new.tap(&:switch) }

  def time_table(name)
    referential.time_tables.where(Chouette::TimeTable.arel_table[:comment].matches("% #{name}")).first
  end

  def vehicle_journey(name)
    referential.vehicle_journeys.find_by(published_journey_name: name)
  end

  let(:old_timetable) { time_table('Old') }
  let(:old_vehicle_journey) { vehicle_journey('Old') }

  let(:previous_timetable) { time_table('Previous') }
  let(:previous_vehicle_journey) { vehicle_journey('Previous') }

  let(:new_timetable) { time_table('New') }
  let(:new_vehicle_journey) { vehicle_journey('New') }

  context "when the workgroup has the option 'enable_purge_merged_data'" do
    before { workgroup.update enable_purge_merged_data: true }

    context 'after merge' do
      before { workgroup.update maximum_data_age: maximum_age }
      before { merge.merge! }

      context 'when maximum age is zero' do
        let(:maximum_age) { 0 }

        it 'cleans an old TimeTable' do
          expect(old_timetable).to be_nil
        end

        it 'cleans an old Vehicle Journey' do
          expect(old_vehicle_journey).to be_nil
        end

        it 'keeps a previous TimeTable (ending today)' do
          expect(previous_timetable).to_not be_nil
        end

        it 'keeps a previous Vehicle Journey (ending today)' do
          expect(previous_vehicle_journey).to_not be_nil
        end

        it 'keeps a new TimeTable' do
          expect(new_timetable).to_not be_nil
        end

        it 'keeps a new Vehicle Journey' do
          expect(new_vehicle_journey).to_not be_nil
        end

        it 'removes/truncates metadatas before today' do
          expect(merge.new.validity_period.begin).to eq(Time.zone.today)
        end
      end

      context 'when the maximum age is 3 days' do
        let(:maximum_age) { 3 }

        it 'cleans an old TimeTable' do
          expect(old_timetable).to be_nil
        end

        it 'cleans an old Vehicle Journey' do
          expect(old_vehicle_journey).to be_nil
        end

        it 'keeps an previous TimeTable (ending today)' do
          expect(previous_timetable).to_not be_nil
        end

        it 'keeps an previous Vehicle Journey (ending today)' do
          expect(previous_vehicle_journey).to_not be_nil
        end

        it 'keeps a new TimeTable' do
          expect(new_timetable).to_not be_nil
        end

        it 'keeps a new Vehicle Journey' do
          expect(new_vehicle_journey).to_not be_nil
        end

        it 'removes/truncates metadatas before 3 days' do
          expect(merge.new.validity_period.begin).to eq(Time.zone.today - maximum_age)
        end
      end

      context 'when maximum age is older than the old timetable' do
        let(:maximum_age) { 5 }

        it 'keeps an old TimeTable' do
          expect(old_timetable).to_not be_nil
        end

        it 'keeps an old Vehicle Journey' do
          expect(old_vehicle_journey).to_not be_nil
        end

        it 'keeps an previous TimeTable (ending today)' do
          expect(previous_timetable).to_not be_nil
        end

        it 'keeps an previous Vehicle Journey (ending today)' do
          expect(previous_vehicle_journey).to_not be_nil
        end

        it 'keeps a new TimeTable' do
          expect(new_timetable).to_not be_nil
        end

        it 'keeps a new Vehicle Journey' do
          expect(new_vehicle_journey).to_not be_nil
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
      expect(old_timetable).to_not be_nil
    end

    it 'keeps an old Vehicle Journey' do
      expect(old_vehicle_journey).to_not be_nil
    end

    it 'keeps an previous TimeTable (ending today)' do
      expect(previous_timetable).to_not be_nil
    end

    it 'keeps an previous Vehicle Journey (ending today)' do
      expect(previous_vehicle_journey).to_not be_nil
    end

    it 'keeps a new TimeTable' do
      expect(new_timetable).to_not be_nil
    end

    it 'keeps a new Vehicle Journey' do
      expect(new_vehicle_journey).to_not be_nil
    end

    it 'leaves unchanged metadatas' do
      expect(merge.new.validity_period.begin).to eq(1.month.ago.to_date)
    end
  end
end
