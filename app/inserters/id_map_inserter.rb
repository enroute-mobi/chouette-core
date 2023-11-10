class IdMapInserter < ByClassInserter

  attr_reader :target
  def initialize(target, options = {})
    @target = target
    options.each { |k,v| send "#{k}=", v }
  end

  attr_accessor :strict
  alias strict? strict

  def new_primary_key!(model_class, old_primary_key)
    new_primary_key = self.for(model_class).new_primary_key(old_primary_key)

    if new_primary_key.nil? && strict?
      raise "No new primary key for #{model_class.name}:#{old_primary_key}"
    end

    new_primary_key
  end

  def new_vehicle_journey_primary_key!(old_primary_key)
    @vehicle_journey_inserter ||= self.for(Chouette::VehicleJourney)
    @vehicle_journey_inserter.new_primary_key(old_primary_key)
  end

  def new_stop_point_primary_key!(old_primary_key)
    @stop_point_inserter ||= self.for(Chouette::StopPoint)
    @stop_point_inserter.new_primary_key(old_primary_key)
  end

  def new_time_table_primary_key!(old_primary_key)
    @time_table_inserter ||= self.for(Chouette::TimeTable)
    @time_table_inserter.new_primary_key(old_primary_key)
  end

  # Reserved to test
  def register_primary_key!(model_class, old_primary_key, new_primary_key)
    self.for(model_class).register_primary_key old_primary_key, new_primary_key
  end

  def self.mapped_model_class?(model_class)
    # TODO Creates a nice method in model class :)
    ! Apartment.excluded_models.include?(model_class.name)
  end

  class Base

    attr_reader :model_class, :parent_inserter

    def initialize(model_class, parent_inserter)
      @model_class = model_class
      @parent_inserter = parent_inserter

      @current_primary_key = load_current_primary_key
      @new_primary_keys ||= Hash.new
    end

    def insert(model, options = {})
      update_relations model unless options[:skip_id_map_update_relations]

      update_primary_key model
    end

    def new_primary_key(old_primary_key)
      @new_primary_keys[old_primary_key]
    end

    def register_primary_key(old_primary_key, new_primary_key)
      if @new_primary_keys.has_key?(old_primary_key)
        raise "A model with primary key #{old_primary_key} already inserted"
      end
      @new_primary_keys[old_primary_key] = new_primary_key
    end

    def has_primary_key?
      ! model_class.column_for_attribute(:id).null
    end

    def update_primary_key(model)
      return unless has_primary_key?
      current_primary_key = model.id

      unless current_primary_key
        raise "No existing primary key for #{model.inspect}"
      end

      new_primary_key = next_primary_key
      register_primary_key current_primary_key, new_primary_key
      model.id = new_primary_key
    end

    def update_relations(model)
      relation_updaters.each do |updater|
        updater.update model
      end
    end

    def relation_updaters
      @relation_updaters ||= create_relation_updaters_on_reflection
    end

    def create_relation_updaters_on_reflection
      # We need to use a set to de-duplicate belongs_to relations
      # Some models have "light" relations which duplicate some relations
      model_class.reflect_on_all_associations(:belongs_to).map do |relation|
        # Doesn't support polymorphic relations
        if IdMapInserter.mapped_model_class?(relation.klass)
          RelationUpdater.new relation.foreign_key, relation.klass, parent_inserter
        end
      end.compact.to_set
    end

    def next_primary_key
      @current_primary_key += 1
    end

    def load_current_primary_key
      return 0 unless has_primary_key?

      parent_inserter.target.switch do
        # When using a cursor, the cursor scope is present
        model_class.unscope(:where).maximum(:id) || 0
      end
    end

    def flush
      @new_primary_keys.clear
    end

  end

  class TimeTable < Base

    def update_relations(timetable)
      # We want to ignore the TimeTable created_from
      timetable.created_from_id = nil
      super
    end

  end

  class VehicleJourneyAtStop < Base

    def load_current_primary_key
      parent_inserter.target.switch do |target|
        # When using a cursor, the cursor scope is present
        target.vehicle_journey_at_stops.unscope(:where).maximum(:id) || 0
      end
    end

    def update_primary_key(model)
      model.id = next_primary_key
    end

    def update_relations(vehicle_journey_at_stop)
      if (vehicle_journey_id = vehicle_journey_at_stop.vehicle_journey_id)
        vehicle_journey_at_stop.vehicle_journey_id =
          parent_inserter.new_vehicle_journey_primary_key!(vehicle_journey_id)
      end

      if (stop_point_id = vehicle_journey_at_stop.stop_point_id)
        if (new_stop_point_id = parent_inserter.new_stop_point_primary_key!(stop_point_id))
          vehicle_journey_at_stop.stop_point_id = new_stop_point_id
        end
      end
    end

  end

  class TimeTableDate < Base

    def update_primary_key(model)
      model.id = next_primary_key
    end

    def update_relations(date)
      if (time_table_id = date.time_table_id)
        date.time_table_id =
          parent_inserter.new_time_table_primary_key!(time_table_id)
      end
    end

  end

  class ReferentialCode < Base

    def update_relations(code)
      if (resource_id = code.resource_id)
        unless code.resource_type == 'Chouette::VehicleJourney'
          raise "Doesn't support other resource than VehicleJourney (for the moment)"
        end
        code.resource_id = parent_inserter.new_vehicle_journey_primary_key!(resource_id)
      end
    end

  end

  class RelationUpdater

    attr_reader :attribute, :associated_model_class, :primary_key_resolver

    def initialize(attribute, associated_model_class, primary_key_resolver)
      @attribute = attribute.to_s
      @associated_model_class = associated_model_class
      @primary_key_resolver = primary_key_resolver
    end

    def update(model)
      old_primary_key = model.send(attribute)
      return if old_primary_key.nil?

      new_primary_key = retrieve_associated_model_id!(old_primary_key)
      model.send "#{attribute}=", new_primary_key if new_primary_key
    end

    def retrieve_associated_model_id!(old_primary_key)
      primary_key_resolver.new_primary_key!(associated_model_class, old_primary_key)
    end

    def eql?(other)
      attribute == other.attribute &&
      associated_model_class == other.associated_model_class
    end

    def hash
      [ attribute, associated_model_class.name ].hash
    end

    def inspect
      "#<IdMapInserter::RelationUpdater:#{hash} @attribute=#{attribute}, @associated_model_class=#{associated_model_class.name}"
    end

  end

end
