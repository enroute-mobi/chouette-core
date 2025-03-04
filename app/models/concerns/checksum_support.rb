module ChecksumSupport
  extend ActiveSupport::Concern
  SEPARATOR = '|'
  VALUE_FOR_NIL_ATTRIBUTE = '-'

  included do |into|
    before_save do
      Chouette::ChecksumManager.watch self
    end

    Referential.register_model_with_checksum self
    into.extend ClassMethods
  end

  module ClassMethods
    def is_checksum_enabled?; true end

    def has_checksum_children klass, opts={}
      Chouette::ChecksumManager.current.log "Define callback in #{klass} to update checksums #{self.model_name}"
      unless klass.respond_to?(:checksum_parent_relations)
        klass.define_singleton_method :checksum_parent_relations do
          @checksum_parent_relations ||= {}
        end
      end
      klass.checksum_parent_relations[self] = opts

      klass.after_save     { Chouette::ChecksumManager.child_after_save(self) }
    end
  end

  def checksum_attributes(db_lookup = true)
    self.attributes.values
  end

  def checksum_replace_nil_or_empty_values values
    # Replace empty array by nil & nil by VALUE_FOR_NIL_ATTRIBUTE
    values
      .map { |x| x.present? && x || VALUE_FOR_NIL_ATTRIBUTE }
      .map do |item|
        item =
          if item.kind_of?(Array)
            checksum_replace_nil_or_empty_values(item)
          else
            item
          end
      end
  end

  def current_checksum_source(db_lookup: true)
    source = checksum_replace_nil_or_empty_values(self.checksum_attributes(db_lookup))
    source += self.custom_fields_checksum if self.respond_to?(:custom_fields_checksum)
    source.map{ |item|
      if item.kind_of?(Array)
        item.map{ |x| x.kind_of?(Array) ? "(#{x.join(',')})" : x }.join(',')
      else
        item
      end
    }.join(SEPARATOR)
  end

  def set_current_checksum_source(db_lookup: true)
    self.checksum_source = self.current_checksum_source(db_lookup: db_lookup)
  end

  def update_checksum(force: false, silent: false)
    if self.checksum_source_changed? || force
      self.checksum = Digest::SHA256.new.hexdigest(self.checksum_source)
    end
    if (self.checksum_source_changed? || self.checksum_changed?) && !silent
      Chouette::ChecksumManager.current.log("Changed #{self.class.name}:#{id} checksum: #{self.checksum}, checksum_source: #{self.checksum_source}")
    end
  end

  def update_checksum!
    _checksum_source = current_checksum_source
    update checksum_source: _checksum_source, checksum: Digest::SHA256.new.hexdigest(_checksum_source)
    Chouette::ChecksumManager.current.log("Updated #{self.class.name}:#{id} checksum: #{self.checksum}")
  end

  def update_checksum_without_callbacks!(db_lookup: true)
    set_current_checksum_source(db_lookup: db_lookup)
    _checksum = Digest::SHA256.new.hexdigest(checksum_source)
    Chouette::ChecksumManager.current.log("Compute checksum for #{self.class.name}:#{id} checksum_source:'#{checksum_source}' checksum: #{_checksum}")
    if _checksum != self.checksum
      self.checksum = _checksum
      self.update_columns(checksum: _checksum, checksum_source: checksum_source) unless self.new_record?
      Chouette::ChecksumManager.current.log("Updated without callback #{self.class.name}:#{id} checksum: #{self.checksum}, checksum_source: #{self.checksum_source}")
    else
      Chouette::ChecksumManager.current.log("Checksum remained unchanged: #{_checksum}")
    end
  end
end
