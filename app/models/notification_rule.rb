class NotificationRule < ApplicationModel
  extend Enumerize
  enumerize :notification_type, in: %w(hole_sentinel), default: :hole_sentinel

  # Associations
  belongs_to :workbench
  belongs_to :line, class_name: 'Chouette::Line'

  # Scopes
  scope :in_periode, -> (daterange) { where('period && daterange(:begin, :end)', begin: daterange.min, end: daterange.max + 1.day) } #Need to add one day because of PostgreSQL behaviour with daterange (exclusvive end)
  scope :covering, -> (daterange) { where('period @> daterange(:begin, :end)', begin: daterange.min, end: daterange.max) }

  # Validations
  validates_presence_of :workbench
  validates_presence_of :line
  validates_presence_of :notification_type
  validates_presence_of :period

  def name
    NotificationRule.tmf('name', notification_type: "notification_rules.notification_types.#{notification_type}".t, from: I18n.l(period.begin), to: I18n.l(period.end))
  end
end
