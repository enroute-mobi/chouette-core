class ImportQuery
  def initialize(scope)
    @scope = scope
  end
  attr_accessor :scope

  def text(value)
    return self if value.blank?

    self.scope = scope.where('imports.name ILIKE ?', "%#{value}%")
    self
  end

  def statuses(values)
    return self if values.blank?

    self.scope = scope.having_status(values)
    self
  end

  def workbench(values)
    return self if values.blank?

    self.scope = scope.where(workbench: [values])
    self
  end

  def include_in_date_range(date_range)
    return self unless date_range.present?
    self.scope = scope.where(started_at: date_range)
    self
  end
end
