module TimetableSupport
  extend ActiveSupport::Concern

  def presenter
    @presenter ||= ::TimeTablePresenter.new( self)
  end

  def periods_max_date
    return nil if self.periods.empty?

    min_start = self.periods.map(&:period_start).compact.min
    max_end = self.periods.map(&:period_end).compact.max
    result = nil

    if max_end && min_start
      max_end.downto( min_start) do |date|
        if self.valid_days.include?(date.cwday) && !self.excluded_date?(date)
            result = date
            break
        end
      end
    end
    result
  end

  def periods_min_date
    return nil if self.periods.empty?

    min_start = self.periods.map(&:period_start).compact.min
    max_end = self.periods.map(&:period_end).compact.max
    result = nil

    if max_end && min_start
      min_start.upto(max_end) do |date|
        if self.valid_days.include?(date.cwday) && !self.excluded_date?(date)
            result = date
            break
        end
      end
    end
    result
  end

  def bounding_dates
    bounding_min = self.all_dates.select{|d| d.in_out}.map(&:date).compact.min
    bounding_max = self.all_dates.select{|d| d.in_out}.map(&:date).compact.max

    unless self.periods.empty?
      bounding_min = periods_min_date if periods_min_date &&
          (bounding_min.nil? || (periods_min_date < bounding_min))

      bounding_max = periods_max_date if periods_max_date &&
          (bounding_max.nil? || (bounding_max < periods_max_date))
    end

    [bounding_min, bounding_max].compact
  end

  def month_inspect(date)
    (date.beginning_of_month..date.end_of_month).map do |d|
      {
        day: I18n.l(d, format: '%A'),
        date: d.to_s,
        wday: d.wday,
        wnumber: d.strftime("%W").to_s,
        mday: d.mday,
        include_date: include_in_dates?(d),
        excluded_date: excluded_date?(d)
      }
    end
  end

  def include_in_dates?(day)
    self.dates.any?{ |d| d.date === day && d.in_out == true }
  end

  def excluded_date?(day)
    self.dates.any?{ |d| d.date === day && d.in_out == false }
  end

  def include_in_overlap_dates?(day)
    return false if self.excluded_date?(day)

    self.all_dates.any?{ |d| d.date === day} \
    && self.periods.any?{ |period| period.period_start <= day && day <= period.period_end && valid_days.include?(day.cwday) }
  end

  def include_in_periods?(day)
    self.periods.any?{ |period| period.period_start <= day &&
                                day <= period.period_end &&
                                valid_days.include?(day.cwday) &&
                                ! excluded_date?(day) }
  end

  # Returns a Period on boundings dates
  def period
    from, to = bounding_dates
    Period.new(from: from, to: to)
  end

  def state_update state
    update_attributes(self.class.state_permited_attributes(state))
    self.calendar_id = nil if self.respond_to?(:calendar_id) && !state['calendar']

    days = state['day_types'].split(',')
    Date::DAYNAMES.map(&:underscore).each do |name|
      prefix = human_attribute_name(name).first(2)
      send("#{name}=", days.include?(prefix))
    end

    # Delete dates to avoid overlap and build or update dates in memory
    deleted_dates = []
    state['current_month'].each do |d|
      date    = Date.parse(d['date'])
      checked = d['include_date'] || d['excluded_date']
      in_out  = d['include_date'] ? true : false

      date_id = saved_dates.key(date)
      time_table_date = self.find_date_by_id(date_id) if date_id

      if checked && time_table_date.present?
        self.update_in_out time_table_date, in_out # Update date
      elsif checked && time_table_date.blank?
        self.build_date in_out, date # Build date
      elsif !checked && time_table_date.present?
        deleted_dates << time_table_date # Delete date
      end
    end
    deleted_dates.each do |deleted_date|
      dates.delete deleted_date
    end

    # Delete periods to avoid overlap and build or update periods in memory
    deleted_periods = []
    state_periods = state['time_table_periods'].delete_if do |item|
      if item['deleted']
        period = self.find_period_by_id(item['id'])
        deleted_periods << period
        true
      else
        false
      end
    end
    self.delete_periods(deleted_periods)

    state_periods.each do |item|
      period = self.find_period_by_id(item['id']) if item['id']
      period ||= self.build_period

      period.period_start = Date.parse(item['period_start'])
      period.period_end   = Date.parse(item['period_end'])
    end

    self.save
  end

end
