module DashboardsHelper
  def render_widget(widget)
    render "dashboards/widgets/#{widget.widget_type}", widget: widget
  end

  def widget_type_color(widget_type)
    base_classes = 'shadow-sm hover:shadow transition-shadow duration-200 rounded-r-lg'
    
    colors = {
      'chart' => "#{base_classes} bg-gradient-to-r from-blue-50 to-white border-l-4 border-blue-400",
      'counter' => "#{base_classes} bg-gradient-to-r from-green-50 to-white border-l-4 border-green-400",
      'list' => "#{base_classes} bg-gradient-to-r from-purple-50 to-white border-l-4 border-purple-400",
      'numbers' => "#{base_classes} bg-gradient-to-r from-yellow-50 to-white border-l-4 border-yellow-400",
      'static_text' => "#{base_classes} bg-gradient-to-r from-pink-50 to-white border-l-4 border-pink-400",
      'table' => "#{base_classes} bg-gradient-to-r from-indigo-50 to-white border-l-4 border-indigo-400",
      'image' => "#{base_classes} bg-gradient-to-r from-red-50 to-white border-l-4 border-red-400"
    }.freeze
    
    colors[widget_type] || colors['default']
  end

  def widget_icon(widget_type)
    icons = {
      'chart' => 'fa-chart-line text-blue-500',
      'counter' => 'fa-hashtag text-green-500',
      'list' => 'fa-list-ul text-purple-500',
      'numbers' => 'fa-calculator text-yellow-600',
      'static_text' => 'fa-paragraph text-pink-500',
      'table' => 'fa-table text-indigo-500'
    }.freeze
    
    icon_class = icons[widget_type] || 'fa-image text-cyan-500'
    content_tag(:i, '', class: "fa #{icon_class} mr-2 text-xl")
  end
end