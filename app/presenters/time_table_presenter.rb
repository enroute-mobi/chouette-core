class TimeTablePresenter

  def default_year(current = Date.current)
    @time_table.period.limit(current).year
  end

  def initialize(time_table)
    @time_table = time_table
  end

  def time_table_bounding
    return I18n.t('time_tables.time_table.empty') if @time_table.bounding_dates.empty?
    "#{I18n.l(@time_table.bounding_dates.min)} #{I18n.l(@time_table.bounding_dates.max)}"
  end

  def composition_info
    return if @time_table.bounding_dates.empty?
    if @time_table.dates.empty?
      I18n.t('time_tables.time_table.periods_count', :count => @time_table.periods.count)
    elsif @time_table.periods.empty?
      I18n.t('time_tables.time_table.dates_count', :count => @time_table.dates.count)
    else
      I18n.t('time_tables.time_table.periods_dates_count',
        :dates_count => @time_table.dates.count,
        :periods_count => @time_table.periods.count)
    end
  end

private
  def bounding_info
    return I18n.t('time_tables.time_table.empty') if @time_table.bounding_dates.empty?
    I18n.t('time_tables.time_table.bounding',
        :start => l(@time_table.bounding_dates.min),
        :end => l(@time_table.bounding_dates.max))
  end

end
