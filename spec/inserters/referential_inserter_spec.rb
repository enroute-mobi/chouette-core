include ReferentialCopyHelpers

RSpec.describe ReferentialInserter do

  let(:context) do
    Chouette.create do
      referential :source do
        purchase_window :purchase_window_1
        purchase_window :purchase_window_2
        time_table :timetable_1
        time_table :timetable_2
        route stop_count: 25 do
          vehicle_journey time_tables: [:timetable_1, :timetable_2]
          vehicle_journey time_tables: [:timetable_2], purchase_windows: [:purchase_window_2]
          vehicle_journey purchase_windows: [:purchase_window_1, :purchase_window_2]
        end
      end
      referential :target do
        time_table :timetable_3
        time_table :timetable_4
        purchase_window :purchase_window_3
        purchase_window :purchase_window_4
        route stop_count: 25 do
          vehicle_journey time_tables: [:timetable_3, :timetable_4], purchase_windows: [:purchase_window_3, :purchase_window_4]
        end
      end
    end
  end

  before do
    context.referential(:source).switch
  end


  subject { ReferentialInserter.new context.referential(:target) }
  alias_method :inserter, :subject

  def dummy_copy_vehicle_journeys
    # dummy mappings
    source_route_id = Chouette::VehicleJourney.first.route_id
    target_route_id = context.referential(:target).switch{Chouette::VehicleJourney.first.route_id}

    source_journey_pattern_id = Chouette::VehicleJourney.first.journey_pattern_id
    target_journey_pattern_id = context.referential(:target).switch{Chouette::VehicleJourney.first.journey_pattern_id}

    inserter.id_map_inserter.register_primary_key!(Chouette::Route, source_route_id, target_route_id)
    inserter.id_map_inserter.register_primary_key!(Chouette::JourneyPattern, source_journey_pattern_id, target_journey_pattern_id)

    Chouette::VehicleJourney.all.each do |vj|
      inserter.vehicle_journeys << vj
    end
  end

  describe "Vehicle Journey" do
    before do
      @vj_source_init_count = Chouette::VehicleJourney.count
      @vj_target_init_count = context.referential(:target).switch{Chouette::VehicleJourney.count}
      @vj_target_max_id = context.referential(:target).switch{Chouette::VehicleJourney.maximum(:id)}

      dummy_copy_vehicle_journeys

      inserter.flush
    end

    it "creates the right number of new records in the target referential" do
      expect(context.referential(:target).switch{Chouette::VehicleJourney.count}).to eq(@vj_source_init_count+@vj_target_init_count)
    end

    it "creates new records in the target referential with the right id" do
      expect(context.referential(:target).switch{Chouette::VehicleJourney.maximum(:id)}).to eq(@vj_target_max_id+@vj_source_init_count)
    end

  end

  describe "Vehicle Journey At Stops" do
    before do
      @vjas_source_init_count = Chouette::VehicleJourneyAtStop.count
      @vjas_target_init_count = context.referential(:target).switch{Chouette::VehicleJourneyAtStop.count}
      @vjas_target_max_id = context.referential(:target).switch{Chouette::VehicleJourneyAtStop.maximum(:id)}

      dummy_copy_vehicle_journeys
      Chouette::VehicleJourneyAtStop.all.each do |vjas|
        inserter.vehicle_journey_at_stops << vjas
      end

      inserter.flush
    end

    it "creates the right number of new records in the target referential" do
      expect(context.referential(:target).switch{Chouette::VehicleJourneyAtStop.count}).to eq(@vjas_source_init_count+@vjas_target_init_count)
    end

    it "creates new records in the target referential with the right id" do
      expect(context.referential(:target).switch{Chouette::VehicleJourneyAtStop.maximum(:id)}).to eq(@vjas_target_max_id+@vjas_source_init_count)
    end
  end

  describe "TimeTablesVehicleJourney" do
    before do
      @ttvj_source_init_count = Chouette::TimeTablesVehicleJourney.count
      @ttvj_target_init_count = context.referential(:target).switch{Chouette::TimeTablesVehicleJourney.count}

      dummy_copy_vehicle_journeys

      # Time Table Dummy Mapping
      @source_time_table_1_id = Chouette::TimeTable.first.id
      @source_time_table_2_id = Chouette::TimeTable.last.id

      @target_time_table_1_id = context.referential(:target).switch{ Chouette::TimeTable.first.id }
      @target_time_table_2_id = context.referential(:target).switch{ Chouette::TimeTable.last.id }

      inserter.id_map_inserter.register_primary_key!(Chouette::TimeTable, @source_time_table_1_id, @target_time_table_1_id)
      inserter.id_map_inserter.register_primary_key!(Chouette::TimeTable, @source_time_table_2_id, @target_time_table_2_id)

      Chouette::TimeTablesVehicleJourney.all.each do |ttvj|
        inserter.vehicle_journey_time_table_relationships << ttvj
      end
      inserter.flush
    end

    it "creates the right number of new records in the target referential" do
      expect(context.referential(:target).switch{Chouette::TimeTablesVehicleJourney.count}).to eq(@ttvj_source_init_count+@ttvj_target_init_count)
    end
  end

  describe "VehicleJourneyPurchaseWindowRelationship" do
    before do
      @vjpwr_source_init_count = Chouette::VehicleJourneyPurchaseWindowRelationship.count
      @vjpwr_target_init_count = context.referential(:target).switch{Chouette::VehicleJourneyPurchaseWindowRelationship.count}

      dummy_copy_vehicle_journeys

      # Purchase Window Dummy Mapping
      @source_purchase_window_1_id = Chouette::PurchaseWindow.first.id
      @source_purchase_window_2_id = Chouette::PurchaseWindow.last.id

      @target_purchase_window_1_id = context.referential(:target).switch{ Chouette::PurchaseWindow.first.id }
      @target_purchase_window_2_id = context.referential(:target).switch{ Chouette::PurchaseWindow.last.id }

      inserter.id_map_inserter.register_primary_key!(Chouette::PurchaseWindow, @source_purchase_window_1_id, @target_purchase_window_1_id)
      inserter.id_map_inserter.register_primary_key!(Chouette::PurchaseWindow, @source_purchase_window_2_id, @target_purchase_window_2_id)

      Chouette::VehicleJourneyPurchaseWindowRelationship.all.each do |vjpwr|
        inserter.vehicle_journey_purchase_window_relationships << vjpwr
      end
      inserter.flush
    end

    it "creates the right number of new records in the target referential" do
      expect(context.referential(:target).switch{Chouette::VehicleJourneyPurchaseWindowRelationship.count}).to eq(@vjpwr_source_init_count+@vjpwr_target_init_count)
    end
  end
end
