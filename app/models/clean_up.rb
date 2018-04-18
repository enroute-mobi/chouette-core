class CleanUp < ApplicationModel
  extend Enumerize
  include AASM
  belongs_to :referential
  has_one :clean_up_result

  enumerize :date_type, in: %i(between before after)

  validates_presence_of :begin_date, message: :presence
  validates_presence_of :end_date, message: :presence, if: Proc.new {|cu| cu.date_type == 'between'}
  validates_presence_of :date_type, message: :presence
  validate :end_date_must_be_greater_that_begin_date
  after_commit :perform_cleanup, :on => :create

  def end_date_must_be_greater_that_begin_date
    if self.end_date && self.date_type == 'between' && self.begin_date >= self.end_date
      errors.add(:base, I18n.t('activerecord.errors.models.clean_up.invalid_period'))
    end
  end

  def perform_cleanup
    CleanUpWorker.perform_async(self.id)
  end

  def clean
    referential.switch
    referential.pending_while do
      {}.tap do |result|
        if date_type
          processed = send("destroy_time_tables_#{self.date_type}")
          if processed
            result['time_table']      = processed[:time_tables].try(:count)
            result['vehicle_journey'] = processed[:vehicle_journeys].try(:count)
          end
          result['time_table_date']   = send("destroy_time_tables_dates_#{self.date_type}").try(:count)
          result['time_table_period'] = send("destroy_time_tables_periods_#{self.date_type}").try(:count)
          self.overlapping_periods.each do |period|
            exclude_dates_in_overlapping_period(period)
          end
        end

        destroy_vehicle_journeys_outside_referential
        # Disabled for the moment. See #5372
        # destroy_time_tables_outside_referential

        destroy_vehicle_journeys
        destroy_journey_patterns
        destroy_routes
      end
    end
  end

  def destroy_time_tables_between
    time_tables = Chouette::TimeTable.where('end_date < ? AND start_date > ?', self.end_date, self.begin_date)
    self.destroy_time_tables(time_tables)
  end

  def destroy_time_tables_before
    time_tables = Chouette::TimeTable.where('end_date < ?', self.begin_date)
    self.destroy_time_tables(time_tables)
  end

  def destroy_time_tables_after
    time_tables = Chouette::TimeTable.where('start_date > ?', self.begin_date)
    self.destroy_time_tables(time_tables)
  end

  def destroy_time_tables_dates_before
    Chouette::TimeTableDate.in_dates.where('date < ?', self.begin_date).destroy_all
  end

  def destroy_time_tables_dates_after
    Chouette::TimeTableDate.in_dates.where('date > ?', self.begin_date).destroy_all
  end

  def destroy_time_tables_dates_between
    Chouette::TimeTableDate.in_dates.where('date > ? AND date < ?', self.begin_date, self.end_date).destroy_all
  end

  def destroy_time_tables_periods_before
    Chouette::TimeTablePeriod.where('period_end < ?', self.begin_date).destroy_all
  end

  def destroy_time_tables_periods_after
    Chouette::TimeTablePeriod.where('period_start > ?', self.begin_date).destroy_all
  end

  def destroy_time_tables_periods_between
    Chouette::TimeTablePeriod.where('period_start > ? AND period_end < ?', self.begin_date, self.end_date).destroy_all
  end

  def destroy_time_tables_outside_referential
    # For the moment, only timetable outside of metadatas min/max dates are removed
    metadatas_period = referential.metadatas_period
    time_tables = Chouette::TimeTable.where('end_date < ? or start_date > ?', metadatas_period.min, metadatas_period.max)
    destroy_time_tables(time_tables)
  end

  def destroy_vehicle_journeys_outside_referential
    line_ids = referential.metadatas.pluck(:line_ids).flatten.uniq
    Chouette::VehicleJourney.joins(:route).where(["routes.line_id not in (?)", line_ids]).destroy_all
  end

  def destroy_vehicle_journeys
    Chouette::VehicleJourney.where("id not in (select distinct vehicle_journey_id from time_tables_vehicle_journeys)").destroy_all
  end

  def destroy_journey_patterns
    Chouette::JourneyPattern.where("id not in (select distinct journey_pattern_id from vehicle_journeys)").destroy_all
  end

  def destroy_routes
    Chouette::Route.where("id not in (select distinct route_id from journey_patterns)").destroy_all
  end

  def overlapping_periods
    self.end_date = self.begin_date if self.date_type != 'between'
    Chouette::TimeTablePeriod.where('(period_start, period_end) OVERLAPS (?, ?)', self.begin_date, self.end_date)
  end

  def exclude_dates_in_overlapping_period(period)
    days_in_period  = period.period_start..period.period_end
    day_out         = period.time_table.dates.where(in_out: false).map(&:date)
    # check if day is greater or less then cleanup date
    if date_type != 'between'
      operator = date_type == 'after' ? '>' : '<'
      to_exclude_days = days_in_period.map do |day|
        day if day.public_send(operator, self.begin_date)
      end
    else
      days_in_cleanup_periode = (self.begin_date..self.end_date)
      to_exclude_days = days_in_period & days_in_cleanup_periode
    end

    to_exclude_days.to_a.compact.each do |day|
      # we ensure day is not already an exclude date
      # and that day is not equal to the boundariy date of the clean up
      if !day_out.include?(day) && day != self.begin_date && day != self.end_date
        self.add_exclude_date(period.time_table, day)
      end
    end
  end

  def add_exclude_date(time_table, day)
    day_in = time_table.dates.where(in_out: true).map(&:date)
    unless day_in.include?(day)
      time_table.add_exclude_date(false, day)
    else
      time_table.dates.where(date: day).take.update_attribute(:in_out, false)
    end
  end

  def destroy_vehicle_journey_without_time_table
    Chouette::VehicleJourney.without_any_time_table.destroy_all
  end

  def destroy_time_tables(time_tables)
    results = { :time_tables => [], :vehicle_journeys => [] }
    # Delete vehicle_journey time_table association
    time_tables.each do |time_table|
      time_table.vehicle_journeys.each do |vj|
        vj.time_tables.delete(time_table)
        results[:vehicle_journeys] << vj.destroy if vj.time_tables.empty?
      end
    end
    results[:time_tables] = time_tables.destroy_all
    results
  end

  aasm column: :status do
    state :new, :initial => true
    state :pending
    state :successful
    state :failed

    event :run, after: :log_pending do
      transitions :from => [:new, :failed], :to => :pending
    end

    event :successful, after: :log_successful do
      transitions :from => [:pending, :failed], :to => :successful
    end

    event :failed, after: :log_failed do
      transitions :from => :pending, :to => :failed
    end
  end

  def log_pending
    update_attribute(:started_at, Time.now)
  end

  def log_successful message_attributes
    update_attribute(:ended_at, Time.now)
    CleanUpResult.create(clean_up: self, message_key: :successfull, message_attributes: message_attributes)
  end

  def log_failed message_attributes
    update_attribute(:ended_at, Time.now)
    CleanUpResult.create(clean_up: self, message_key: :failed, message_attributes: message_attributes)
  end
end
