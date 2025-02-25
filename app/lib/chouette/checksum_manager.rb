module Chouette::ChecksumManager
  THREAD_VARIABLE_NAME = "current_checksum_manager".freeze

  class NotInTransactionError < StandardError; end
  class AlreadyInTransactionError < StandardError; end
  class MultipleReferentialsError < StandardError; end

  def self.current
    current_manager = Thread.current.thread_variable_get THREAD_VARIABLE_NAME
    current_manager || self.current = Chouette::ChecksumManager::NoUpdates.new
  end

  def self.current= manager
    Thread.current.thread_variable_set THREAD_VARIABLE_NAME, manager
    manager
  end

  def self.cleanup
    Thread.current.thread_variable_set THREAD_VARIABLE_NAME, nil
  end

  def self.logger
    @@logger ||= Rails.logger
  end

  def self.logger= logger
    @@logger = logger
  end

  def self.log_level
    @@log_level ||= :debug
  end

  def self.log_level= log_level
    @@log_level = log_level if logger.respond_to?(log_level)
  end

  def self.log msg
    prefix = "[ChecksumManager::#{current.class.name.split('::').last} #{current.object_id.to_s(16)}]"
    logger.send log_level, "#{prefix} #{msg}"
  end

  def self.inline
    begin
      self.current = Chouette::ChecksumManager::Inline.new
      yield
    ensure
      self.current = nil
    end
  end

  def self.update_checkum_in_batches(collection, referential)
    collection.find_in_batches do |group|
      ids = []
      checksums = []
      checksum_sources = []
      group.each do |r|
        ids << r.id
        source = r.current_checksum_source(db_lookup: false)
        checksum_sources << ActiveRecord::Base.sanitize_sql(source).gsub(/'/, "''")
        checksums << Digest::SHA256.new.hexdigest(source)
      end
      sql = <<SQL
        UPDATE \"#{referential.slug}\".#{collection.klass.table_name} tmp SET checksum_source = data_table.checksum_source, checksum = data_table.checksum
        FROM
        (select unnest(array[#{ids.join(",")}]) as id,
        unnest(array['#{checksums.join("','")}']) as checksum,
        unnest(array['#{checksum_sources.join("','")}']) as checksum_source) as data_table
        where tmp.id = data_table.id;
SQL
      ActiveRecord::Base.connection.execute sql
    end
  end

  def self.watch object, from: nil
    current.watch object, from: from
  end

  def self.object_signature object
    SerializedObject.new(object).signature
  end

  def self.checksum_parents object
    klass = object.class
    return [] unless klass.respond_to? :checksum_parent_relations
    return [] unless klass.checksum_parent_relations

    parents = []
    klass.checksum_parent_relations.each do |parent_model, opts|
      belongs_to = opts[:relation] || parent_model.model_name.singular
      has_many = opts[:relation] || parent_model.model_name.plural

      if object.respond_to? belongs_to
        reflection = klass.reflections[belongs_to.to_s]
        if reflection
          if object.association(belongs_to.intern).loaded?
            log "parent is already loaded"
            parent = object.send(belongs_to)
            parents << SerializedObject.new(parent, need_save: true, load_object: true) if parent
          else
            log "parent is not loaded but can be inferred from reflection"
            parent_id = object.send(reflection.foreign_key)
            parent_class = reflection.klass.name
          end
        else
          # the relation is not a true ActiveRecord Relation
          log "parent has to be loaded"
          parent = object.send(belongs_to)
          parents << [parent.class.name, parent.id]
        end
        parents << [parent_class, parent_id] if parent_id
      end

      if object.respond_to? has_many
        # XXX: SOME OPTIM POSSIBLE HERE

        if reflection && object.association(has_many.intern).loaded?
          log "#{has_many} parents are already loaded"
          parents += object.send(has_many).map{|p| SerializedObject.new(p, need_save: true)}
        else
          if reflection && !reflection.options[:through]
            log "#{has_many} parent are not loaded but can be inferred from reflection"
            parents += [reflection.klass.name].product(object.send(has_many).pluck(reflection.foreign_key).compact)
          else
            log "#{has_many} parents have to be loaded"
            # the relation is not a true ActiveRecord Relation
            parents += object.send(has_many).map { |p| SerializedObject.new(p, need_save: true, load_object: true)}
          end
        end
      end
    end

    parents.compact
  end

  def self.parents_to_sentence parents
    parents.map do |p|
      if p.is_a?(Array)
        p
      elsif p.respond_to?(:serialized_object)
        p.serialized_object
      else
       [p.class.name, p.id]
     end
    end.group_by(&:first).map{ |klass, v| "#{v.size} #{klass}" }.to_sentence
  end

  def self.child_after_save object
    current.child_after_save(object)
  end
end
