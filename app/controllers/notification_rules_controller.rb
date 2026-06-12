# frozen_string_literal: true

class NotificationRulesController < Chouette::WorkbenchController
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
    @search ||= Search::NotificationRule.from_params(params, workbench: workbench)
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
    params
      .require(:notification_rule)
      .permit(
        :notification_type,
        :priority,
        :rule_type,
        :target_type,
        :external_email,
        users: [],
        operation_statuses: [],
        lines: []
      )
      .with_defaults(workbench_id: workbench.id, users: [], external_email: nil, lines: []) # CHOUETTE-1713
    # (depending on the chosen target_type, some inputs are disabled, we then need to ensure default values)
    # (lines is only shown for import/merge notification types, so we reset it when the input is hidden)
  end
end
