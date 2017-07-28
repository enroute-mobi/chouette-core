class Chouette::TimeTable < Chouette::TridentActiveRecord
  include TimeTableRestrictions
  # FIXME http://jira.codehaus.org/browse/JRUBY-6358
  self.primary_key = "id"

  acts_as_taggable

  attr_accessor :monday,:tuesday,:wednesday,:thursday,:friday,:saturday,:sunday
  attr_accessor :tag_search

  def self.ransackable_attributes auth_object = nil
    (column_names + ['tag_search']) + _ransackers.keys
  end

  has_and_belongs_to_many :vehicle_journeys, :class_name => 'Chouette::VehicleJourney'

  has_many :dates, -> {order(:date)}, inverse_of: :time_table, :validate => :true, :class_name => "Chouette::TimeTableDate", :dependent => :destroy
  has_many :periods, -> {order(:period_start)}, inverse_of: :time_table, :validate => :true, :class_name => "Chouette::TimeTablePeriod", :dependent => :destroy

  belongs_to :calendar
  belongs_to :created_from, class_name: 'Chouette::TimeTable'

  scope :overlapping, -> (date_start, date_end) do
    joins(:periods).where('(period_start, period_end) OVERLAPS (?, ?)', date_start, date_end)
  end

  after_save :save_shortcuts

  def self.object_id_key
    "Timetable"
  end

  accepts_nested_attributes_for :dates, :allow_destroy => :true
  accepts_nested_attributes_for :periods, :allow_destroy => :true

  validates_presence_of :comment
  validates_associated :dates
  validates_associated :periods

  def continuous_dates
    in_days = self.dates.where(in_out: true).sort_by(&:date)
    chunk = {}
    group = nil
    in_days.each_with_index do |date, index|
      group ||= index
      group = (date.date == in_days[index - 1].date + 1.day) ? group : group + 1
      chunk[group] ||= []
      chunk[group] << date
    end
    # Remove less than 2 continuous day chunk
    chunk.values.delete_if {|dates| dates.count < 2}
  end

  def convert_continuous_dates_to_periods
    chunks = self.continuous_dates

    transaction do
      chunks.each do |chunk|
        self.periods.create!(period_start: chunk.first.date, period_end: chunk.last.date)
        self.dates.delete(chunk)
      end
    end
  end

  def state_update state
    update_attributes(self.class.state_permited_attributes(state))
    self.tag_list    = state['tags'].collect{|t| t['name']}.join(', ')
    self.calendar_id = nil unless state['calendar']

    days = state['day_types'].split(',')
    Date::DAYNAMES.map(&:underscore).each do |name|
      prefix = human_attribute_name(name).first(2)
      send("#{name}=", days.include?(prefix))
    end

    saved_dates = Hash[self.dates.collect{ |d| [d.id, d.date]}]
    cmonth = Date.parse(state['current_periode_range'])

    state['current_month'].each do |d|
      date    = Date.parse(d['date'])
      checked = d['include_date'] || d['excluded_date']
      in_out  = d['include_date'] ? true : false

      date_id = saved_dates.key(date)
      time_table_date = self.dates.find(date_id) if date_id

      next if !checked && !time_table_date
      # Destroy date if no longer checked
      next if !checked && time_table_date.destroy

      # Create new date
      unless time_table_date
        time_table_date = self.dates.create({in_out: in_out, date: date})
      end
      # Update in_out
      if in_out != time_table_date.in_out
        time_table_date.update_attributes({in_out: in_out})
      end
    end

    self.state_update_periods state['time_table_periods']
    self.save
  end

  def state_update_periods state_periods
    state_periods.each do |item|
      period = self.periods.find(item['id']) if item['id']
      next if period && item['deleted'] && period.destroy
      period ||= self.periods.build

      period.period_start = Date.parse(item['period_start'])
      period.period_end   = Date.parse(item['period_end'])

      if period.changed?
        period.save
        item['id'] = period.id
      end
    end

    state_periods.delete_if {|item| item['deleted']}
  end

  def self.state_permited_attributes item
    item.slice('comment', 'color').to_hash
  end

  def presenter
    @presenter ||= ::TimeTablePresenter.new( self)
  end

  def self.start_validity_period
    [Chouette::TimeTable.minimum(:start_date)].compact.min
  end
  def self.end_validity_period
    [Chouette::TimeTable.maximum(:end_date)].compact.max
  end

  def add_exclude_date(in_out, date)
    self.dates.create!({in_out: in_out, date: date})
  end

  def actualize
    self.dates.clear
    self.periods.clear
    from = self.calendar.convert_to_time_table
    self.dates   = from.dates
    self.periods = from.periods
    self.save
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

  def save_shortcuts
      shortcuts_update
      self.update_column(:start_date, start_date)
      self.update_column(:end_date, end_date)
  end

  def shortcuts_update(date=nil)
    dates_array = bounding_dates
    #if new_record?
      if dates_array.empty?
        self.start_date=nil
        self.end_date=nil
      else
        self.start_date=dates_array.min
        self.end_date=dates_array.max
      end
    #else
     # if dates_array.empty?
     #   update_attributes :start_date => nil, :end_date => nil
     # else
     #   update_attributes :start_date => dates_array.min, :end_date => dates_array.max
     # end
    #end
  end

  def validity_out_from_on?(expected_date)
    return false unless self.end_date
    self.end_date <= expected_date
  end

  def validity_out_between?(starting_date, ending_date)
    return false unless self.start_date
    starting_date < self.end_date  &&
      self.end_date <= ending_date
  end
  def self.validity_out_from_on?(expected_date,limit=0)
    if limit==0
      Chouette::TimeTable.where("end_date <= ?", expected_date)
    else
      Chouette::TimeTable.where("end_date <= ?", expected_date).limit( limit)
    end
  end
  def self.validity_out_between?(start_date, end_date,limit=0)
    if limit==0
      Chouette::TimeTable.where( "? < end_date", start_date).where( "end_date <= ?", end_date)
    else
      Chouette::TimeTable.where( "? < end_date", start_date).where( "end_date <= ?", end_date).limit( limit)
    end
  end

  # Return days which intersects with the time table dates and periods
  def intersects(days)
    [].tap do |intersect_days|
      days.each do |day|
        intersect_days << day if include_day?(day)
      end
    end
  end

  def include_day?(day)
    include_in_dates?(day) || include_in_periods?(day)
  end

  def include_in_dates?(day)
    self.dates.any?{ |d| d.date === day && d.in_out == true }
  end

  def excluded_date?(day)
    self.dates.any?{ |d| d.date === day && d.in_out == false }
  end

  def include_in_periods?(day)
    self.periods.any?{ |period| period.period_start <= day &&
                                day <= period.period_end &&
                                valid_days.include?(day.cwday) &&
                                ! excluded_date?(day) }
  end

  def include_in_overlap_dates?(day)
    return false if self.excluded_date?(day)

    counter = self.dates.select{ |d| d.date === day}.size + self.periods.select{ |period| period.period_start <= day && day <= period.period_end && valid_days.include?(day.cwday) }.size
    counter <= 1 ? false : true
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
    bounding_min = self.dates.select{|d| d.in_out}.map(&:date).compact.min
    bounding_max = self.dates.select{|d| d.in_out}.map(&:date).compact.max

    unless self.periods.empty?
      bounding_min = periods_min_date if periods_min_date &&
          (bounding_min.nil? || (periods_min_date < bounding_min))

      bounding_max = periods_max_date if periods_max_date &&
          (bounding_max.nil? || (bounding_max < periods_max_date))
    end

    [bounding_min, bounding_max].compact
  end

  def display_day_types
    %w(monday tuesday wednesday thursday friday saturday sunday).select{ |d| self.send(d) }.map{ |d| self.human_attribute_name(d).first(2)}.join(', ')
  end

  def day_by_mask(flag)
    int_day_types & flag == flag
  end

  def self.day_by_mask(int_day_types,flag)
    int_day_types & flag == flag
  end


  def valid_days
    # Build an array with day of calendar week (1-7, Monday is 1).
    [].tap do |valid_days|
      valid_days << 1  if monday
      valid_days << 2  if tuesday
      valid_days << 3  if wednesday
      valid_days << 4  if thursday
      valid_days << 5  if friday
      valid_days << 6  if saturday
      valid_days << 7  if sunday
    end
  end

  def self.valid_days(int_day_types)
    # Build an array with day of calendar week (1-7, Monday is 1).
    [].tap do |valid_days|
      valid_days << 1  if day_by_mask(int_day_types,4)
      valid_days << 2  if day_by_mask(int_day_types,8)
      valid_days << 3  if day_by_mask(int_day_types,16)
      valid_days << 4  if day_by_mask(int_day_types,32)
      valid_days << 5  if day_by_mask(int_day_types,64)
      valid_days << 6  if day_by_mask(int_day_types,128)
      valid_days << 7  if day_by_mask(int_day_types,256)
    end
  end

  def monday
    day_by_mask(4)
  end
  def tuesday
    day_by_mask(8)
  end
  def wednesday
    day_by_mask(16)
  end
  def thursday
    day_by_mask(32)
  end
  def friday
    day_by_mask(64)
  end
  def saturday
    day_by_mask(128)
  end
  def sunday
    day_by_mask(256)
  end

  def set_day(day,flag)
    if day == '1' || day == true
      self.int_day_types |= flag
    else
      self.int_day_types &= ~flag
    end
    shortcuts_update
  end

  def monday=(day)
    set_day(day,4)
  end
  def tuesday=(day)
    set_day(day,8)
  end
  def wednesday=(day)
    set_day(day,16)
  end
  def thursday=(day)
    set_day(day,32)
  end
  def friday=(day)
    set_day(day,64)
  end
  def saturday=(day)
    set_day(day,128)
  end
  def sunday=(day)
    set_day(day,256)
  end

  def effective_days_of_period(period,valid_days=self.valid_days)
    days = []
      period.period_start.upto(period.period_end) do |date|
        if valid_days.include?(date.cwday) && !self.excluded_date?(date)
            days << date
        end
      end
    days
  end

  def effective_days(valid_days=self.valid_days)
    days=self.effective_days_of_periods(valid_days)
    self.dates.each do |d|
      days |= [d.date] if d.in_out
    end
    days.sort
  end

  def effective_days_of_periods(valid_days=self.valid_days)
    days = []
    self.periods.each { |p| days |= self.effective_days_of_period(p,valid_days)}
    days.sort
  end

  def clone_periods
    periods = []
    self.periods.each { |p| periods << p.copy}
    periods.sort_by(&:period_start)
  end

  def included_days
    days = []
    self.dates.each do |d|
      days |= [d.date] if d.in_out
    end
    days.sort
  end

  def excluded_days
    days = []
    self.dates.each do |d|
      days |= [d.date] unless d.in_out
    end
    days.sort
  end


  # produce a copy of periods without anyone overlapping or including another
  def optimize_overlapping_periods
    periods = self.clone_periods
    optimized = []
    i=0
    while i < periods.length
      p1 = periods[i]
      optimized << p1
      j= i+1
      while j < periods.length
        p2 = periods[j]
        if p1.contains? p2
          periods.delete p2
        elsif p1.overlap? p2
          p1.period_start = [p1.period_start,p2.period_start].min
          p1.period_end = [p1.period_end,p2.period_end].max
          periods.delete p2
        else
          j += 1
        end
      end
      i+= 1
    end
    optimized.sort { |a,b| a.period_start <=> b.period_start}
  end

  def continuous_periods
    periods = self.periods.sort_by(&:period_start)
    chunk = {}
    group = nil
    periods.each_with_index do |period, index|
      group ||= index
      group = (period.period_start - 1.day == periods[index - 1].period_end) ? group : group + 1
      chunk[group] ||= []
      chunk[group] << period
    end
    chunk.values.delete_if {|periods| periods.count < 2}
  end

  def convert_continuous_periods_into_one
    chunks = self.continuous_periods

    transaction do
      chunks.each do |chunk|
        self.periods.create!(period_start: chunk.first.period_start, period_end: chunk.last.period_end)
        self.periods.delete chunk
      end
    end
  end

  #update a period if a in_day is just before or after
  def optimize_continuous_dates_and_periods
    return self.periods if self.included_days.empty? || periods.empty?

    periods = self.clone_periods
    optimized = []

    i = 0
    while i < periods.length
      period = periods[i]
      j = 0
      in_days = self.reload.dates.where(in_out: true).sort_by(&:date)
      while j < in_days.length
        day = in_days[j]
        if period.period_start - 1.day === day.date
          period.period_start = day.date
          self.dates.delete day
        elsif period.period_end + 1.day === day.date
          period.period_end = day.date
          self.dates.delete day
        end
        j += 1
      end
      i += 1
      optimized << period
    end
    optimized
  end

  # add a peculiar day or switch it from excluded to included
  def add_included_day(d)
    if self.excluded_date?(d)
       self.dates.each do |date|
         if date.date === d
           date.in_out = true
         end
       end
    elsif !self.include_in_dates?(d)
       self.dates << Chouette::TimeTableDate.new(:date => d, :in_out => true)
    end
  end

  # merge effective days from another timetable
  def merge!(another_tt)
    transaction do
      days = Array.new.tap do |array|
        array.push(*self.included_days_in_dates_and_periods, *another_tt.effective_days)
        array.uniq!
      end

      self.dates.clear
      self.periods.clear

      days.each do |day|
        self.dates << Chouette::TimeTableDate.new(date: day, in_out: true)
      end
      self.save!
    end
    self.convert_continuous_dates_to_periods
  end

  def included_days_in_dates_and_periods
    in_day  = self.dates.select {|d| d.in_out }.map(&:date)
    out_day = self.dates.select {|d| !d.in_out }.map(&:date)

    in_periods = self.periods.map{|p| (p.period_start..p.period_end).to_a }.flatten
    days = in_periods + in_day
    days -= out_day
    days
  end

  # remove dates form tt which aren't in another_tt
  def intersect!(another_tt)
    transaction do
      days = Array.new.tap do |array|
        array.push(*self.included_days_in_dates_and_periods)
        array.delete_if {|day| !another_tt.effective_days.include?(day) }
        array.uniq!
      end

      self.dates.clear
      self.periods.clear

      days.sort.each do |d|
        self.dates << Chouette::TimeTableDate.new(:date => d, :in_out => true)
      end
      self.save!
    end
    self.convert_continuous_dates_to_periods
  end

  # remove days from another calendar
  def disjoin!(another_tt)
    transaction do
      days = Array.new.tap do |array|
        array.push(*self.included_days_in_dates_and_periods)
        array.delete_if {|day| another_tt.effective_days.include?(day) }
        array.uniq!
      end

      self.dates.clear
      self.periods.clear

      days.sort.each do |d|
        self.dates << Chouette::TimeTableDate.new(:date => d, :in_out => true)
      end
      self.save!
    end
    self.convert_continuous_dates_to_periods
  end

  def duplicate
    tt = self.deep_clone :include => [:periods, :dates], :except => :object_version
    tt.uniq_objectid
    tt.tag_list.add(*self.tag_list) unless self.tag_list.empty?
    tt.created_from = self
    tt.comment      = I18n.t("activerecord.copy", :name => self.comment)
    tt
  end
end
