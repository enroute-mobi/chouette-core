class Calendar::DateValue
  include ActiveAttr::Model

  attribute :id, type: Integer
  attribute :value, type: Date

  validates_presence_of :value

  def self.from_date(index, date)
    new id: index, value: date
  end

  # Stuff required for coocon
  def new_record?
    !persisted?
  end

  def persisted?
    id.present?
  end

  def mark_for_destruction
    self._destroy = true
  end

  attribute :_destroy, type: Boolean
  alias_method :marked_for_destruction?, :_destroy
end
