require 'spec_helper'

describe Chouette::RelationshipRecord, :type => :model do

  let(:context) do
    Chouette.create do
      time_table :timetable_1
      time_table :timetable_2
      vehicle_journey time_tables: [:timetable_1, :timetable_2]
      vehicle_journey time_tables: [:timetable_1, :timetable_2]
    end
  end

  describe "find_each_without_primary_key method" do
    before do
      context.referential.switch
      @count = 0
      Chouette::TimeTablesVehicleJourney.find_each_without_primary_key{|d| @count+=1}
    end

    it 'should browse every existing record' do
      expect(@count).to eq 4
    end
  end
end
