# frozen_string_literal: true

class NotificationRule < ApplicationModel
  extend Enumerize

  enumerize :notification_type, in: %w[import merge aggregate source_retrieval publication], default: :import
  enumerize :target_type, in: %w[workbench user external_email], default: :workbench, predicates: true
  enumerize :rule_type, in: %w[block notify], default: :block
  enumerize :operation_statuses, in: %w[successful warning failed], multiple: true

  # Associations
  belongs_to :workbench, class_name: '::Workbench'
  has_one :organisation, through: :workbench
  has_array_of :lines, class_name: 'Chouette::Line'
  has_array_of :users

  # Scopes
  scope :in_period, ->(value) { query.in_period(value).scope }
  scope :covering, lambda { |daterange|
                     where(period: nil).or where('period @> daterange(:begin, :end)', begin: daterange.min, end: daterange.max)
                   }
  scope :active, -> { covering(Time.zone.today..Time.zone.today) }
  scope :by_email, ->(value) { query.email(value).scope }
  scope :for_statuses, ->(value) { query.operation_statuses(value).scope }
  scope :for_lines, ->(value) { query.lines(value).scope }

  class << self
    def for_operation(operation)
      operation_status = operation.try(:user_status) || operation.status
      operation_scope = for_statuses([operation_status]).where(notification_type: operation.class.model_name.singular)

      if (line_ids = operation.try(:line_ids)).present?
        operation_scope = operation_scope.for_lines line_ids
      end

      operation_scope
    end

    def query
      ::Query::NotificationRule.new(all)
    end
  end

  # Validations
  validates :workbench, :notification_type, :target_type, presence: true

  validates :priority, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1, less_than_or_equal_to: 1000
  }
  validates :users, length: { minimum: 1 }, if: proc { |rule| rule.target_type == 'user' }
  validates :external_email, presence: true, if: proc { |rule| rule.target_type == 'external_email' }

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
