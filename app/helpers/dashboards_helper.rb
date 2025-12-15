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

  def widget_type_color(widget_type)
    base_classes = 'shadow-sm hover:shadow transition-shadow duration-200 rounded-r-lg'
    
    colors = {
      'chart' => "#{base_classes} bg-gradient-to-r from-blue-50 to-white border-l-4 border-blue-400",
      'counter' => "#{base_classes} bg-gradient-to-r from-green-50 to-white border-l-4 border-green-400",
      'list' => "#{base_classes} bg-gradient-to-r from-purple-50 to-white border-l-4 border-purple-400",
      'numbers' => "#{base_classes} bg-gradient-to-r from-yellow-50 to-white border-l-4 border-yellow-400",  # Jaune
      'static_text' => "#{base_classes} bg-gradient-to-r from-pink-50 to-white border-l-4 border-pink-400",
      'table' => "#{base_classes} bg-gradient-to-r from-indigo-50 to-white border-l-4 border-indigo-400",
      'default' => "#{base_classes} bg-gradient-to-r from-cyan-50 to-white border-l-4 border-cyan-400"  # Cyan
    }
    
    colors[widget_type] || colors['default']
  end

  def widget_icon(widget_type)
    icon_class = case widget_type
              when 'chart' then 'fa-chart-line text-blue-500'
              when 'counter' then 'fa-hashtag text-green-500'
              when 'list' then 'fa-list-ul text-purple-500'
              when 'numbers' then 'fa-calculator text-yellow-600'  # Jaune plus foncé
              when 'static_text' then 'fa-paragraph text-pink-500'
              when 'table' then 'fa-table text-indigo-500'
              else 'fa-cat text-cyan-500'
              end
    content_tag(:i, '', class: "fa #{icon_class} mr-2 text-xl")
  end
end