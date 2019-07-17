class CleanUp < ApplicationModel
  extend Enumerize
  include CleanUpMethods
  include AASM
  belongs_to :referential
  has_one :clean_up_result

  enumerize :date_type, in: %i(outside between before after)

  # WARNING: the order here is meaningful
  enumerize :data_cleanups, in: %i(
    clean_vehicle_journeys_without_time_table
    clean_journey_patterns_without_vehicle_journey
    clean_routes_without_journey_pattern
    clean_unassociated_timetables
    clean_unassociated_purchase_windows
  ), multiple: true

  # validates_presence_of :date_type, message: :presence
  validates_presence_of :begin_date, message: :presence, if: :date_type
  validates_presence_of :end_date, message: :presence, if: Proc.new {|cu| cu.needs_both_dates? }
  validate :end_date_must_be_greater_that_begin_date
  after_commit :perform_cleanup, :on => :create

  scope :for_referential, ->(referential) do
    where(referential_id: referential.id)
  end

  attr_accessor :clean_methods, :original_state

  def end_date_must_be_greater_that_begin_date
    if self.end_date && needs_both_dates? && self.begin_date >= self.end_date
      errors.add(:base, I18n.t('activerecord.errors.models.clean_up.invalid_period'))
    end
  end

  def needs_both_dates?
    date_type == 'between'  || date_type == 'outside'
  end

  def perform_cleanup
    raise "You cannot specify methods (#{clean_methods.inspect}) if you call the CleanUp asynchronously" unless clean_methods.blank?

    original_state ||= referential.state
    referential.pending!

    enqueue_job :clean!, original_state
  end

  def clean!(original_state)
    self.original_state = original_state
    run if may_run?
    begin
      referential.switch
      result = clean
      # cleaner.successful(result)
    rescue Exception => e
      Rails.logger.error "CleanUpWorker : #{e}"
      # cleaner.failed({error: e.message})
      log_failed({})
    end
  end

  def clean
    referential.switch
    referential.pending_while do
      clean_timetables_and_children
      clean_routes_outside_referential
      run_methods
    end

    Chouette::Benchmark.log('reset_referential_state') do
      if original_state.present? && referential.respond_to?("#{original_state}!")
        referential.send("#{original_state}!")
      end
    end
  end

  def run_methods
    (clean_methods || []).each { |method| send(method) }
    data_cleanups.each { |method| send(method) }
  end

  def overlapping_periods
    self.end_date = self.begin_date if self.date_type != 'between'
    Chouette::TimeTablePeriod.where('(period_start, period_end) OVERLAPS (?, ?)', self.begin_date, self.end_date)
  end

  # def exclude_dates_in_overlapping_period(period)
  #   days_in_period  = period.period_start..period.period_end
  #   day_out         = period.time_table.dates.where(in_out: false).map(&:date)
  #   # check if day is greater or less then cleanup date
  #   if date_type != 'between'
  #     operator = date_type == 'after' ? '>' : '<'
  #     to_exclude_days = days_in_period.map do |day|
  #       day if day.public_send(operator, self.begin_date)
  #     end
  #   else
  #     days_in_cleanup_periode = (self.begin_date..self.end_date)
  #     to_exclude_days = days_in_period & days_in_cleanup_periode
  #   end
  #
  #   to_exclude_days.to_a.compact.each do |day|
  #     # we ensure day is not already an exclude date
  #     # and that day is not equal to the boundary date of the clean up
  #     if !day_out.include?(day) && day != self.begin_date && day != self.end_date
  #       self.add_exclude_date(period.time_table, day)
  #     end
  #   end
  # end

  # def add_exclude_date(time_table, day)
  #   day_in = time_table.dates.where(in_out: true).map(&:date)
  #   unless day_in.include?(day)
  #     time_table.add_exclude_date(false, day)
  #   else
  #     time_table.dates.where(date: day).take.update_attribute(:in_out, false)
  #   end
  # end

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
