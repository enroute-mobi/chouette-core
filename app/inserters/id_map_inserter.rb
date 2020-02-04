class IdMapInserter < ByClassInserter

  def new_primary_key!(model_class, old_primary_key)
    new_primary_key = self.for(model_class).new_primary_key(old_primary_key)

    unless new_primary_key
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

  # Reserved to test
  def register_primary_key!(model_class, old_primary_key, new_primary_key)
    self.for(model_class).register_primary_key old_primary_key, new_primary_key
  end

  class Base

    attr_reader :model_class, :parent_inserter

    def initialize(model_class, parent_inserter)
      @model_class = model_class
      @parent_inserter = parent_inserter

      @next_primary_key = 0
      @new_primary_keys ||= Hash.new
    end

    def insert(model)
      update_relations model

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

    def update_primary_key(model)
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
        RelationUpdater.new relation.foreign_key, relation.klass, parent_inserter
      end.to_set
    end

    def next_primary_key
      @next_primary_key += 1
    end

  end

  class VehicleJourneyAtStop < Base

    def register_primary_key(old_primary_key, new_primary_key)
    end

    def update_relations(vehicle_journey_at_stop)
      if vehicle_journey_id = vehicle_journey_at_stop.vehicle_journey_id
        vehicle_journey_at_stop.vehicle_journey_id =
          parent_inserter.new_vehicle_journey_primary_key!(vehicle_journey_id)
      end

      if stop_point_id = vehicle_journey_at_stop.stop_point_id
        vehicle_journey_at_stop.stop_point_id =
          parent_inserter.new_stop_point_primary_key!(stop_point_id)
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
      model.send "#{attribute}=", new_primary_key
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
