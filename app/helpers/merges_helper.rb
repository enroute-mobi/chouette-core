module MergesHelper
  def merge_status(merge)
    content_tag :span, '' do
      concat(content_tag(:span, '', class: 'status') do
        concat operation_status(merge.status)
      end)
      if merge.is_current?
        concat(content_tag(:span, '', class: 'current') do
          concat render_current_icon
        end)
      end
      if merge.contains_urgent_offer?
        concat(content_tag(:span, '', class: 'contains_urgent_offer') do
          concat render_urgent_icon
        end)
      end
    end
  end

  def render_current_icon
    render_icon 'sb sb-compliance_control_set', I18n.t('merges.show.table.state.title')
  end

  def render_urgent_icon
    render_icon 'fa fa-flag', I18n.t('merges.show.table.state.urgent'), 'color: #da2f36'
  end
end
