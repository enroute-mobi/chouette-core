# frozen_string_literal: true

class NotificationRulesController < Chouette::WorkbenchController
  include RansackDateFilter

  defaults resource_class: NotificationRule

  def index
    index! do |format|
      format.html {
        @notification_rules = NotificationRuleDecorator.decorate(
          collection,
          context: {
            workbench: workbench
          }
        )
      }
    end
  end

  def scope
    parent.notification_rules
  end

  def search
    @search ||= Search::NotificationRule.from_params(params)
  end

  def collection
    @collection ||= search.search scope
  end

  protected

  def build_resource
    get_resource_ivar || set_resource_ivar(super.decorate(context: { workbench: parent }))
  end

  def resource
    get_resource_ivar || set_resource_ivar(super.decorate(context: { workbench: parent }))
  end

  private

  def notification_rule_params
    # TODO This horrible hack is made to avoid errors when PostgreSQL read empty string for period
    if params['notification_rule'] && params['notification_rule']['period'].blank?
      params['notification_rule']['period'] = nil
    end
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
      .with_defaults(workbench_id: workbench.id, users: [], external_email: nil) # CHOUETTE-1713
    # (depending on the chosen target_type, some inputs are disabled, we then need to ensure default values)
  end
end
