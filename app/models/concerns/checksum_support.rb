module ChecksumSupport
  extend ActiveSupport::Concern
  SEPARATOR = '|'
  VALUE_FOR_NIL_ATTRIBUTE = '-'

  included do
    before_save :update_checksum
  end

  def checksum_attributes
    raise NotImplementedError,
      "all models including #{ChecksumSupport} need to implement class instance method #{__method__}" 
  end
  def dependency_checksums
    []
  end

  def current_checksum_source
    checksum_attributes.map do | value |
      value.blank? ? VALUE_FOR_NIL_ATTRIBUTE : value
    end
     .join(SEPARATOR)
  end

  def update_checksum
    self.checksum_source = current_checksum_source
    if self.checksum_source_changed?
      self.checksum = Digest::SHA256.new.hexdigest(self.checksum_source)
    end
  end
end
