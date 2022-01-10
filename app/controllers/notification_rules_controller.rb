class NotificationRulesController < ChouetteController
  include PolicyChecker
  include RansackDateFilter

  defaults resource_class: NotificationRule
  belongs_to :workbench

  def index
    index! do |format|
      format.html {
        @notification_rules = NotificationRuleDecorator.decorate(
          collection,
            context: {
              workbench: @workbench
            }
        )
      }
    end
  end

  def new
    @notification_rule = NotificationRule.new.decorate(context: { workbench: parent })
    new!
  end

  def show
    show! do
      @notification_rule = @notification_rule.decorate(context: { workbench: parent })
    end
  end

  def edit
    edit! do
      @notification_rule = @notification_rule.decorate(context: { workbench: parent })
    end
  end

  def scope
    parent.notification_rules
  end

  def search
    @search ||= Search::NotificationRule.new(scope, params)
  end

  delegate :collection, to: :search

  private

  def notification_rule_params
    params
      .require(:notification_rule)
      .permit(
        :notification_type,
        :priority,
        :rule_type,
        :target_type,
        :external_email,
        :period,
        user_ids: [],
        operation_statuses: [],
        line_ids: [],
        workbench_id: parent.id
      )
      .with_defaults(workbench_id: parent.id)
      .delete_if { |k,v| v.blank? } # Need to remove empty string values because of period column (the pg daterange adapter try to split a non existing range)
  end
end
