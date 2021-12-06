class NotificationRulesController < ChouetteController
  include PolicyChecker
  include RansackDateFilter
  before_action(only: [:index]) { set_date_time_params("period", Date, prefix: :notification_rule) }

  defaults resource_class: NotificationRule
  belongs_to :workbench

  def index
    index! do |format|
      scope = ransack_period_range(scope: @notification_rules, error_message:  t('referentials.errors.validity_period'), query: :in_periode, prefix: :notification_rule)
      @q = scope.ransack(params[:q])

      format.html {
        @notification_rules = NotificationRuleDecorator.decorate(
          @q.result(distinct: true).paginate(page: params[:page]),
            context: {
              workbench: @workbench
            }
        )
      }
    end
  end

  def new
    @notification_rule = NotificationRule.new(workbench_id: parent.id).decorate
    new!
  end

  def show
    show! do
      @notification_rule = @notification_rule.decorate(context: { workbench: @workbench })
    end
  end

  private

  def notification_rule_params
    params.require(:notification_rule).permit(
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
    ).with_defaults(workbench_id: parent.id)
  end
end
