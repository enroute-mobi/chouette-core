module ChecksumSupport
  extend ActiveSupport::Concern
  SEPARATOR = '|'
  VALUE_FOR_NIL_ATTRIBUTE = '-'

  included do |into|
    before_save :set_current_checksum_source, :update_checksum
    Referential.register_model_with_checksum self
    into.extend ClassMethods
  end

  module ClassMethods
    def has_checksum_children klass, opts={}
      parent_class = self
      relation = opts[:relation] || self.model_name.singular
      klass.after_save do
        parent = self.send(relation)
        parent&.update_checksum_without_callbacks!
      end
    end
  end

  def checksum_attributes
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

  def current_checksum_source
    source = checksum_replace_nil_or_empty_values(self.checksum_attributes)
    source.map{ |item|
      if item.kind_of?(Array)
        item.map{ |x| x.kind_of?(Array) ? "(#{x.join(',')})" : x }.join(',')
      else
        item
      end
    }.join(SEPARATOR)
  end

  def set_current_checksum_source
    self.checksum_source = self.current_checksum_source
  end

  def update_checksum
    if self.checksum_source_changed?
      self.checksum = Digest::SHA256.new.hexdigest(self.checksum_source)
    end
  end

  def update_checksum!
    set_current_checksum_source
    if checksum_source_changed?
      update checksum: Digest::SHA256.new.hexdigest(checksum_source)
    end
  end

  def update_checksum_without_callbacks!
    set_current_checksum_source
    _checksum = Digest::SHA256.new.hexdigest(checksum_source)
    if _checksum != self.checksum
      self.checksum = _checksum
      self.class.where(id: self.id).update_all(checksum: _checksum) unless self.new_record?
    end
  end
end
