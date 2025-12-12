module DashboardsHelper
  def render_widget(widget)
    case widget.widget_type
    when 'default'
      render 'dashboards/widgets/default', widget: widget
    when 'chart'
      render 'dashboards/widgets/chart', widget: widget
    when 'counter'
      render 'dashboards/widgets/counter', widget: widget
    when 'list'
      render 'dashboards/widgets/list', widget: widget
    when 'numbers'
      render 'dashboards/widgets/numbers', widget: widget
    when 'static_text'
      render 'dashboards/widgets/static_text', widget: widget
    when 'table'
      render 'dashboards/widgets/table', widget: widget
    else
      content_tag(:div, t('dashboards.widgets.unknown_type', widget_type: widget.widget_type), class: 'alert alert-warning')
    end
  end
end