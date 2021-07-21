class ImportQuery
  def initialize(scope)
    @scope = scope
  end
  attr_accessor :scope

  def self.status_group
    {
      'pending' => ['new', 'pending', 'running'],
      'failed' => ['failed', 'aborted', 'canceled'],
      'warning' => ['warning'],
      'successful' => ['successful']
    }
  end

  def find_import_statuses(values)
    values.map{ |value| ImportQuery.status_group[value]}.flatten.compact
  end

  def call(params = {})
    scope = text(params[:name])
    scope = statuses(params[:status])
  end


  def text(value)
   return scope if value.blank?
   self.scope = scope.where("name ILIKE ?", "%#{value}%")
  end

  def statuses(values)
   return scope if values.blank?

   import_statuses = find_import_statuses(values)
   self.scope = scope.having_status(import_statuses)
  end

  def include_start_date(begin_date, end_date)
    return scope if (begin_date.blank? && end_date.blank?)

    if begin_date.present && end_date.present
      self.scope = scope.started_at_between(begin_date, end_date)
    elsif begin_date.present?
      self.scope = scope.started_at_after(end_date)
    elsif end_date.present?
      self.scope = scope.started_at_before(end_date)
    else
      return scope
    end

  end

end
