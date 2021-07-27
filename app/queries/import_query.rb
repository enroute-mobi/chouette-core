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

  def include_start_date(begin_date, end_date)
    return self if begin_date.blank? && end_date.blank?

    if begin_date.present && end_date.present
      self.scope = scope.started_at_between(begin_date, end_date)
    elsif begin_date.present?
      self.scope = scope.started_at_after(end_date)
    elsif end_date.present?
      self.scope = scope.started_at_before(end_date)
    end
    self
  end
end
