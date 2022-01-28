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
    # TODO This horrible hack is made to avoid errors when PostgreSQL read empty string for period start and period end
    puts "*" * 25
    params['notification_rule']['period'] = nil if params['notification_rule']['period'] == ""
    puts params.inspect
    params
      .require(:notification_rule)
      .permit(
        :notification_type,
        :priority,
        :rule_type,
        :target_type,
        :external_email,
        :period,
        users: [],
        operation_statuses: [],
        lines: []
      )
      .with_defaults(workbench_id: parent.id, users: [], external_email: nil) # CHOUETTE-1713 (depending on the chosen target_type, some inputs are disabled, we then need to ensure default values)
  end
end
