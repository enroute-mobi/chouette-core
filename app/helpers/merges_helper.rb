module MergesHelper
  def merge_status(merge)
    content_tag :span, '' do
      concat operation_status(merge.status)
      concat render_current_icon if merge.is_current?
      concat render_urgent_icon if merge.contains_urgent_offer?
    end
  end

  def render_current_icon
    render_icon 'sb sb-compliance_control_set', I18n.t('merges.show.table.state.title')
  end

  def render_urgent_icon
    render_icon 'fa fa-flag', I18n.t('merges.show.table.state.urgent'), 'color: #da2f36'
  end

  def merge_metadatas(merge)
    {
      Merge.tmf(:referentials) => merge.referentials.map{ |r| link_to(decorate_referential_name(r), workbench_referential_path(merge.workbench, r)) }.join(', ').html_safe,
      Merge.tmf(:status) => operation_status(merge.status, verbose: true, i18n_prefix: "merges.statuses"),
      Merge.tmf(:new) => merge.new ? link_to(merge.new.name, workbench_referential_path(merge.workbench, merge.new)) : '-',
      Merge.tmf(:contains_urgent_offer) => boolean_icon(merge.contains_urgent_offer?)
    }
  end
end
