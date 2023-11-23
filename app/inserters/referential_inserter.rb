class ReferentialInserter

  def initialize(referential)
    @referential = referential

    if block_given?
      yield Config.new(self)
    end
  end
  attr_reader :referential

  def inserters
    @inserters ||= []
  end

  def id_map_inserter
    @id_map_inserter ||= inserters.find { |i| i.is_a? IdMapInserter }
  end

  class Config

    def initialize(referential_inserter)
      @referential_inserter = referential_inserter
    end

    def add(inserter_class, options = {})
      referential_inserter.inserters << build(inserter_class, options)
    end
    alias << add

    private

    attr_reader :referential_inserter
    delegate :referential, to: :referential_inserter

    def build(inserter_class, options = {})
      inserter_class.new referential_inserter.referential, options
    end

  end

  def insert(model, options = {})
    inserters.each do |inserter|
      inserter.insert model, options
    end
  end

  def flush
    Chouette::Benchmark.measure "referential_inserter/flush", referential: referential.id do
      inserters.each do |inserter|
        inserter.flush if inserter.respond_to?(:flush)
      end
    end
  end

  def collection
    @collection ||= Collection.new self
  end

  COLLECTION_ALIASES = %i{
    vehicle_journeys
    vehicle_journey_at_stops
    vehicle_journey_time_table_relationships
    time_tables
    time_table_dates
    time_table_periods
    codes
    service_counts
  }.freeze

  COLLECTION_ALIASES.each do |method_name|
    alias_method method_name, :collection
  end

  # Only syntax suggar (in order to parse something like this : inserter.vehicle_journeys << new_vj), there is no logic embeded within this class
  class Collection

    def initialize parent
      @parent = parent
    end

    delegate :insert, to: :parent
    alias << insert

    attr_reader :parent
  end
end
