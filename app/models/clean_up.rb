class CleanUp < ApplicationModel
  extend Enumerize
  include CleanUpMethods
  include AASM
  belongs_to :referential # TODO: CHOUETTE-3247 optional: true?
  has_one :clean_up_result

  enumerize :date_type, in: %i(outside between before after)

  # WARNING: the order here is meaningful
  enumerize :data_cleanups, in: %i(
    clean_vehicle_journeys_without_time_table
    clean_journey_patterns_without_vehicle_journey
    clean_routes_without_journey_pattern
    clean_unassociated_timetables
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
      clean
    rescue Exception => e
      Chouette::Safe.capture "CleanUp ##{id} failed", e
      log_failed({})
    end
  end

  def worker_died
    failed({
      error: "Worker has been killed"
    })

    Rails.logger.error "#{self.class.name} #{self.inspect} failed due to worker being dead"
  end


  def clean
    referential.switch

    Chouette::Benchmark.measure("referential.clean", referential: referential.id) do
      referential.pending_while do
        clean_timetables_and_children
        clean_routes_outside_referential
        run_methods
      end

      Chouette::Benchmark.measure('reset_referential_state') do
        if original_state.present? && referential.respond_to?("#{original_state}!")
          referential.send("#{original_state}!")
        end
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
      transitions :from => [:new, :pending], :to => :failed
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
