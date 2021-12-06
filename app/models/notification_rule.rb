class NotificationRule < ApplicationModel
  extend Enumerize

  enumerize :notification_type, in: %w(hole_sentinel import merge), default: :hole_sentinel
  enumerize :target_type, in: %w(user workbench external_email), default: :workbench, predicates: { prefix: true }
  enumerize :rule_type, in: %w(notify block), default: :block, scope: true
  enumerize :operation_statuses, in: %w(success warning error), multiple: true

  # Associations
  belongs_to :workbench

  # Scopes
  scope :in_periode, -> (daterange) { where('period && daterange(:begin, :end)', begin: daterange.min, end: daterange.max + 1.day) } #Need to add one day because of PostgreSQL behaviour with daterange (exclusvive end)
  scope :covering, -> (daterange) { where('period @> daterange(:begin, :end)', begin: daterange.min, end: daterange.max) }
  
  operation_statuses.values.each do |value|
    scope value.to_sym, -> { where('array_length(operation_status, 1) = 0 OR operation_status::text[] @> ARRAY[?]', value) }
  end

  # Validations
  validates_presence_of :workbench
  validates_presence_of :notification_type
  validates_presence_of :target_type
  validates_presence_of :period
  # validates_presence_of :external_email, if: Proc.new(&:target_type_external_email?)
  # validates_length_of :user_ids, minimum: 1, if: Proc.new(&:target_type_user?)
  validates_length_of :line_ids, minimum: 1

  validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000 }

  def name
    NotificationRule.tmf('name', notification_type: "notification_rules.notification_types.#{notification_type}".t, from: I18n.l(period.begin), to: I18n.l(period.end))
  end

  def users
    workbench.users.where(id: user_is)
  end

  def lines
    workbench.lines.where(id: line_ids)
  end
end
