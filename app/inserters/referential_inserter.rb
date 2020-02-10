class ReferentialInserter

  attr_accessor :id_map_inserter

  def initialize referential
    @referential = referential
  end

  def copy_inserter
    @copy_inserter ||= CopyInserter.new(@referential)
  end

  def id_map_inserter
    @id_map_inserter ||= IdMapInserter.new(@referential)
  end

  def insert model
    id_map_inserter.insert model
    copy_inserter.insert model
  end

  def flush
    id_map_inserter.flush
    copy_inserter.flush
  end

  def collection
    @collection ||= CollectionInserter.new self
  end

  [:vehicle_journeys, :vehicle_journey_at_stops, :vehicle_journey_time_table_relationships, :time_tables_vehicle_journeys, :vehicle_journey_purchase_window_relationships].each do |method_name|
    alias_method method_name, :collection
  end

  class CollectionInserter

    def initialize parent
      @parent = parent
    end

    def << model
      @parent.insert model
    end

  end
end
