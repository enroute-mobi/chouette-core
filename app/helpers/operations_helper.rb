module OperationsHelper
  def operation_status(status, verbose: false, default_status: nil, i18n_prefix: nil)
    status = status.status if status.respond_to?(:status)
    status ||= default_status
    return unless status
    i18n_prefix ||= "operation_support.statuses"
    status = status.to_s.downcase

    txt = "#{i18n_prefix}.#{status}".t(fallback: "")
    title = verbose ? nil : txt

    out = if %w[new running pending].include? status
      render_icon "fa fa-clock-o #{status}", title
    else
      cls = ''
      cls = 'success' if status == 'successful'
      cls = 'success' if status == 'ok'
      cls = 'warning' if status == 'warning'
      cls = 'warning' if status == 'successful_with_warnings'
      cls = 'disabled' if status == 'canceled'
      cls = 'danger' if %w[failed aborted error].include? status

      render_icon "fa fa-circle text-#{cls}", title
    end
    if verbose
      out += content_tag :span , txt
    end
    out
  end
end
