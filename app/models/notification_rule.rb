class NotificationRule < ApplicationModel
  extend Enumerize

  enumerize :notification_type, in: %w(hole_sentinel import merge), default: :hole_sentinel
  enumerize :target_type, in: %w(workbench user external_email), default: :workbench, predicates: true
  enumerize :rule_type, in: %w(block notify), default: :block
  enumerize :operation_statuses, in: %w(successful warning failed), multiple: true

  # Associations
  belongs_to :workbench, class_name: '::Workbench'
  has_one :organisation, through: :workbench

  # Scopes
  scope :in_periode, -> (value) { query.period(value).scope }
  scope :covering, -> (daterange) { where('period @> daterange(:begin, :end)', begin: daterange.min, end: daterange.max) }
  scope :active, -> { covering(Date.today..Date.today) }
  scope :by_email, -> (value) { query.email(value).scope }
  scope :for_statuses, -> (value) { query.operation_statuses(value).scope }
  scope :for_line_ids, -> (value) { query.line_ids(value).scope }

  scope :for_operation, -> (operation, line_ids) do
    for_statuses([operation.status]).for_line_ids(line_ids).where(notification_type: operation.class.model_name.singular)
  end

  def self.query
    ::Query::NotificationRule.new(all)
  end

  # Validations
  validates_presence_of :workbench
  validates_presence_of :notification_type
  validates_presence_of :target_type
  validates_presence_of :period

  validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000 }

  self.inheritance_column = 'target_type'

  def self.find_sti_class(target_type)
    super("NotificationRule::#{target_type.classify}")
  end

    def self.inherited(child)
      child.instance_eval do
        def model_name
          NotificationRule.model_name
        end
      end
      super
  end
end
