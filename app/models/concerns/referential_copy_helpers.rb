module ReferentialCopyHelpers
  def copy_bulk_collection collection, &block
    target.switch do
      collection.klass.bulk_insert do |worker|
        each_item_in_source_collection(collection) do |item|
          attributes = clean_attributes_for_copy item, strict: false
          block.call(attributes, item) if block_given?
          target.switch(verbose: false) do
            worker.add attributes
          end
        end
      end
    end
  end

  def copy_collection source_item, target_item, collection_name, &block
    each_item_in_source_collection(source_item.send(collection_name)) do |item|
      copy_item_to_target_collection item, target_item.send(collection_name), &block
    end
  end

  # from: the object you read the collection from
  # to: the object owning the collection you want to fill
  # find_collection: the collection used to find the objects in the source referential
  # collection_name: the name of the collection
  # keys: the keys used to identify the objects across both referentials
  # select (optional): the fields to query on the source collection

  def retrieve_collection_with_mapping from, to, find_collection, collection_name
    queries = []
    if from.is_a? Chouette::RoutingConstraintZone
      # we need the dirty switch because of the has_many_in_array stuff
      from_collection = source.switch(verbose: false) { from.send(collection_name).to_a }
    else
      from_collection = from.send(collection_name).select(:id)
    end

    to_collection = to.send(collection_name)
    each_item_in_source_collection(from_collection) do |item|
      target.switch(verbose: false) do
        to_collection << find_collection.find(matching_id(item))
      end
    end
  end

  def each_item_in_source_collection collection
    source.switch do
      meth = collection.respond_to?(:find_each) ? :find_each : :each
      collection = collection.reorder(nil) if meth == :find_each
      collection.send(meth) do |item|
        yield item
      end
    end
  end

  def copy_item_to_target_collection source_item, target_collection, &block
    attributes = clean_attributes_for_copy source_item
    owner = target_collection.instance_variable_get("@association").owner
    target.switch do
      new_item = target_collection.build attributes
      block.call(source_item, new_item) if block.present?
      if owner.persisted?
        controlled_save! new_item
        record_match source_item, new_item
      else
        waiting_for_save_to_record_match(source_item, new_item)
      end
    end
  end

  def clean_attributes_for_copy model, strict: true
    removed_attrs = %w(id created_at updated_at opposite_route_id)
    removed_attrs += %w(position) if strict

    model.attributes.dup.except(*removed_attrs)
  end

  def controlled_save! model, worker=nil
    profile_tag "save_model.#{model.class.name}" do
      begin
        if worker && model.new_record?
          model.validate!
          worker.add clean_attributes_for_copy model
        else
          model.save!
        end
      rescue => e
        error = []
        error << e.message
        error << model.class.name
        error << model.attributes
        error << model.errors.messages
        error = error.join("\n")

        raise SaveError.new(error)
      end
      process_wait_queue
    end
  end

  def clean_matches *models
    models.each do |model|
      @matches[model.name] = {}
    end
  end

  def matches
    @matches ||= Hash.new { |hash, key| hash[key] = {} }
  end

  def record_match(source_item, copied_item)
    matches[source_item.class.name][source_item.id] = copied_item.id
  end

  def matching_id(item)
    return unless item
    matches[item.class.name][item.id]
  end

  def waiting_for_save_to_record_match(source_item, copied_item)
    @wait_queue ||= []
    @wait_queue.push [source_item, copied_item]
  end

  def process_wait_queue
    @wait_queue ||= []
    new_queue = []
    @wait_queue.each do |source_item, copied_item|
      if copied_item.persisted?
        record_match source_item, copied_item
      else
        new_queue.push [source_item, copied_item]
      end
    end
    @wait_queue = new_queue
  end

  def failed! error
    @status = :failed
    @last_error = error
  end

  class SaveError < RuntimeError
  end
end
