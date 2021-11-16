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

  def state_update_periods state_periods
    # Delete periods before save new or updated to avoid overlapped periods
    state_periods.delete_if do |item|
      if item['deleted']
        period = self.find_period_by_id(item['id']) if item['id']
        if period
          self.destroy_period(period)
        end
        true
      else
        false
      end
    end


    state_periods.each do |item|
      period = self.find_period_by_id(item['id']) if item['id']
      period ||= self.build_period

      period.period_start = Date.parse(item['period_start'])
      period.period_end   = Date.parse(item['period_end'])

      period.save if period.is_a?(ActiveRecord::Base) && period.changed?

      item['id'] = period.id
    end
  end

  def state_update state
    update_attributes(self.class.state_permited_attributes(state))
    self.tag_list    = state['tags'].collect{|t| t['label']}.join(', ') if state['tags']
    self.calendar_id = nil if self.respond_to?(:calendar_id) && !state['calendar']

    days = state['day_types'].split(',')
    Date::DAYNAMES.map(&:underscore).each do |name|
      prefix = human_attribute_name(name).first(2)
      send("#{name}=", days.include?(prefix))
    end

    cmonth = Date.parse(state['current_periode_range'])

    state['current_month'].each do |d|
      date    = Date.parse(d['date'])
      checked = d['include_date'] || d['excluded_date']
      in_out  = d['include_date'] ? true : false

      date_id = saved_dates.key(date)
      time_table_date = self.find_date_by_id(date_id) if date_id

      next if !checked && !time_table_date
      # Destroy date if no longer checked
      next if !checked && destroy_date(time_table_date)

      # Create new date
      unless time_table_date
        time_table_date = self.create_date in_out: in_out, date: date
      end
      # Update in_out
      self.update_in_out time_table_date, in_out
    end

    self.state_update_periods state['time_table_periods']
    self.save
  end

end
