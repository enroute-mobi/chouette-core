RSpec.describe Merge do
  let(:context) do
    Chouette.create do
      referential periods: [ 1.month.ago.to_date..1.month.from_now.to_date ] do
        time_table :timetable_1, periods: [ 1.month.ago.to_date..Time.zone.today-1 ]
        time_table :timetable_2

        vehicle_journey time_tables: [:timetable_1, :timetable_2]
        vehicle_journey time_tables: [:timetable_1]
        vehicle_journey time_tables: [:timetable_2]
      end
    end
  end
  let(:workbench) { context.workbench }
  let(:workgroup) { context.workgroup }
  let(:merge) do
    Merge.new created_at: Time.now, workbench: workbench, referentials: [context.referential]
  end

  it "should not cleanup timetables if workgroup doesn't have enable_purge_merged_data" do
    merge.merge!

    output = merge.output.current
    output.switch do
      expect(Chouette::TimeTable.count).to eq 2
      expect(Chouette::VehicleJourney.count).to eq 3
    end
  end

  it "should cleanup timetables if workgroup have enable_purge_merged_data" do
    workgroup.enable_purge_merged_data = true
    workgroup.save

    merge.merge!

    output = merge.output.current
    output.switch do
      expect(Chouette::TimeTable.count).to eq 1
      expect(Chouette::VehicleJourney.count).to eq 2
    end
  end

  it "should not cleanup timetables if workgroup have enable_purge_merged_data but old maximum_data_age" do
    workgroup.enable_purge_merged_data = true
    workgroup.maximum_data_age = 5
    workgroup.save

    merge.merge!

    output = merge.output.current
    output.switch do
      expect(Chouette::TimeTable.count).to eq 2
      expect(Chouette::VehicleJourney.count).to eq 3
    end
  end
end
