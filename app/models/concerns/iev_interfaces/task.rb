module IevInterfaces::Task
  extend ActiveSupport::Concern

  included do
    belongs_to :parent, polymorphic: true
    belongs_to :workbench, class_name: "::Workbench"
    belongs_to :referential

    mount_uploader :file, ImportUploader

    has_many :children, foreign_key: :parent_id, class_name: self.name, dependent: :destroy

    extend Enumerize
    enumerize :status, in: %w(new pending successful warning failed running aborted canceled), scope: true, default: :new

    validates :name, presence: true
    validates_presence_of :workbench, :creator

    has_many :messages, class_name: messages_class_name, dependent: :destroy, foreign_key: "#{messages_class_name.split('::').first.downcase}_id"
    has_many :resources, class_name: resources_class_name, dependent: :destroy, foreign_key: "#{resources_class_name.split('::').first.downcase}_id"

    scope :where_started_at_in, ->(period_range) do
      where('started_at BETWEEN :begin AND :end', begin: period_range.begin, end: period_range.end)
    end

    scope :for_referential, ->(referential) do
      where(referential_id: referential.id)
    end

    scope :blocked, -> { where('created_at < ? AND status = ?', 4.hours.ago, 'running') }

    before_save :initialize_fields, on: :create
    after_save :notify_parent
  end

  module ClassMethods
    def launched_statuses
      %w(new pending)
    end

    def failed_statuses
      %w(failed aborted canceled)
    end

    def finished_statuses
      %w(successful failed warning aborted canceled)
    end

    def abort_old
      where(
        'created_at < ? AND status NOT IN (?)',
        4.hours.ago,
        finished_statuses
      ).update_all(status: 'aborted')
    end
  end

  def notify_parent
    return false unless self.class.finished_statuses.include?(status)

    return false unless parent.present?
    return false if notified_parent_at
    parent.child_change

    update_column :notified_parent_at, Time.now
    true
  end

  def children_succeedeed
    children.with_status(:successful, :warning).count
  end

  def update_status
    Rails.logger.info "update_status for #{inspect}"
    status =
      if children.where(status: self.class.failed_statuses).count > 0
        'failed'
      elsif children.where(status: "warning").count > 0
        'warning'
      elsif children.where(status: "successful").count == children.count
        'successful'
      else
        'running'
      end

    attributes = {
      current_step: children.count,
      status: status
    }

    if self.class.finished_statuses.include?(status)
      attributes[:ended_at] = Time.now
    end

    update attributes
  end

  def successful?
    status.to_s == "successful"
  end

  def child_change
    return if self.class.finished_statuses.include?(status)
    update_status
  end

  def call_iev_callback
    return if self.class.finished_statuses.include?(status)
    threaded_call_boiv_iev
  end

  private

  def threaded_call_boiv_iev
    Thread.new(&method(:call_boiv_iev))
  end

  def call_boiv_iev
    Rails.logger.error("Begin IEV call for import")
    Net::HTTP.get iev_callback_url
    Rails.logger.error("End IEV call for import")
  rescue Exception => e
    logger.error "IEV server error : #{e.message}"
    logger.error e.backtrace.inspect
  end

  private
  def initialize_fields
  end
end
