class NotificationRule < ApplicationModel
  extend Enumerize

  enumerize :notification_type, in: %w(import merge aggregate hole_sentinel), default: :import
  enumerize :target_type, in: %w(workbench user external_email), default: :workbench, predicates: true
  enumerize :rule_type, in: %w(block notify), default: :block
  enumerize :operation_statuses, in: %w(successful warning failed), multiple: true

  # Associations
  belongs_to :workbench, class_name: '::Workbench'
  has_one :organisation, through: :workbench
  has_array_of :lines, class_name: 'Chouette::Line'
  has_array_of :users

  # Scopes
  scope :in_period, -> (value) { query.in_period(value).scope }
  scope :covering, -> (daterange) { where('period @> daterange(:begin, :end)', begin: daterange.min, end: daterange.max) }
  scope :active, -> { covering(Time.zone.today..Time.zone.today) }
  scope :by_email, -> (value) { query.email(value).scope }
  scope :for_statuses, -> (value) { query.operation_statuses(value).scope }
  scope :for_line_ids, -> (value) { query.line_ids(value).scope }

  def self.for_operation(operation)
    operation_scope = for_statuses([operation.status]).
                      where(notification_type: operation.class.model_name.singular)

    if operation.respond_to? :line_ids
      operation_scope = operation_scope.for_line_ids operation.line_ids
    end

    operation_scope
  end

  def self.query
    ::Query::NotificationRule.new(all)
  end

  # Validations
  validates :workbench, :notification_type, :target_type, presence: true

  validates :priority, numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1, less_than_or_equal_to: 1000
            }
  validates :user_ids, length: { minimum: 1 }, if: Proc.new { |rule| rule.target_type == 'user' }

  def target_class
    "#{self.class}::Target::#{target_type.classify}".constantize
  end

  def target
    @target ||= target_class.new(self)
  end
  delegate :recipients, to: :target

  def self.recipients(initial_recipients = [])
    all.reduce(initial_recipients) do |recipients, rule|
			case rule.rule_type
			when 'notify'
          recipients | rule.recipients
			when 'block'
        recipients - rule.recipients
			else
        recipients
			end
		end.uniq
  end

  module Target
    class Base
      def initialize(notification_rule)
        @notification_rule = notification_rule
      end

      attr_reader :notification_rule
      delegate :workbench, to: :notification_rule
    end

    class ExternalEmail < Base
      delegate :external_email, to: :notification_rule

      def recipients
        [external_email]
      end
    end

    class Workbench < Base
      delegate :users, to: :workbench
      def recipients
        users.pluck(:email)
      end
    end

    class User < Base
      delegate :user_ids, to: :notification_rule
      def users
        workbench.users.where(id: user_ids)
      end
      def recipients
        users.pluck(:email)
      end
    end
  end
end
