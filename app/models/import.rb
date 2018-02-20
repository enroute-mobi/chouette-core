class Import < ActiveRecord::Base
  mount_uploader :file, ImportUploader
  belongs_to :workbench
  belongs_to :referential

  belongs_to :parent, polymorphic: true

  has_many :messages, class_name: "ImportMessage", dependent: :destroy
  has_many :resources, class_name: "ImportResource", dependent: :destroy
  has_many :children, foreign_key: :parent_id, class_name: "Import", dependent: :destroy

  scope :where_started_at_in, ->(period_range) do
    where('started_at BETWEEN :begin AND :end', begin: period_range.begin, end: period_range.end)
   end

  scope :blocked, -> { where('created_at < ? AND status = ?', 4.hours.ago, 'running') }

  extend Enumerize
  enumerize :status, in: %w(new pending successful warning failed running aborted canceled), scope: true, default: :new

  validates :name, presence: true
  validates :file, presence: true
  validates_presence_of :workbench, :creator

  before_create :initialize_fields

  def self.model_name
    ActiveModel::Name.new Import, Import, "Import"
  end

  def children_succeedeed
    children.with_status(:successful, :warning).count
  end

  def self.launched_statuses
    %w(new pending)
  end

  def self.failed_statuses
    %w(failed aborted canceled)
  end

  def self.finished_statuses
    %w(successful failed warning aborted canceled)
  end

  def self.abort_old
    where(
      'created_at < ? AND status NOT IN (?)',
      4.hours.ago,
      finished_statuses
    ).update_all(status: 'aborted')
  end

  def notify_parent
    parent.child_change
    update(notified_parent_at: DateTime.now)
  end

  def child_change
    return if self.class.finished_statuses.include?(status)

    update_status
    update_referentials
  end

  def update_status
    status =
      if children.where(status: self.class.failed_statuses).count > 0
        'failed'
      elsif children.where(status: "warning").count > 0
        'warning'
      elsif children.where(status: "successful").count == children.count
        'successful'
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

  def update_referentials
    return unless self.class.finished_statuses.include?(status)

    children.each do |import|
      import.referential.update(ready: true) if import.referential
    end
  end

  private

  def initialize_fields
    self.token_download = SecureRandom.urlsafe_base64
  end

end
