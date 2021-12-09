module NotificationRulesHelper
  def operation_statuses_options
    NotificationRule.operation_statuses.values.map {|i| {id: i, text: "#{NotificationRule.operation_statuses.i18n_scopes.first}.#{i}".t} }
  end
end
