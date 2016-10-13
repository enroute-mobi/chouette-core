class StopAreaReferentialSync < ActiveRecord::Base
  include AASM
  belongs_to :stop_area_referential
  has_many :stop_area_referential_sync_messages, :dependent => :destroy

  after_commit :perform_sync, :on => :create
  validate :multiple_process_validation, :on => :create

  private
  def perform_sync
    create_sync_message :info, :new
    StopAreaReferentialSyncWorker.perform_async(self.id)
  end

  # There can be only one instance running
  def multiple_process_validation
    if self.class.where(status: [:new, :pending], stop_area_referential_id: stop_area_referential_id).count > 0
      errors.add(:base, :multiple_process)
    end
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

  def create_sync_message criticity, key, message_attributs = {}
    params = {
      criticity: criticity,
      message_key: key,
      message_attributs: message_attributs
    }
    stop_area_referential_sync_messages.create params
  end

  def log_pending
    update_attribute(:started_at, Time.now)
    create_sync_message :info, :pending
  end

  def log_successful message_attributs
    update_attribute(:ended_at, Time.now)
    create_sync_message :info, :successful, message_attributs
  end

  def log_failed message_attributs
    update_attribute(:ended_at, Time.now)
    create_sync_message :error, :failed, message_attributs
  end
end
