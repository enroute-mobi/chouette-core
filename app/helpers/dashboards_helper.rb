# frozen_string_literal: true

module DashboardsHelper
  WIDGET_COLORS_BASE_CLASSES = 'shadow-sm hover:shadow transition-shadow duration-200 rounded-r-lg border-l-4'

  WIDGET_COLORS = {
    'search' => "#{WIDGET_COLORS_BASE_CLASSES} bg-gradient-to-r from-blue-50 to-white border-blue-400",
    'static_text' => "#{WIDGET_COLORS_BASE_CLASSES} bg-gradient-to-r from-pink-50 to-white border-pink-400",
    nil => WIDGET_COLORS_BASE_CLASSES
  }.freeze

  def widget_colors_alpine_class
    to_widget_alpine_class(WIDGET_COLORS)
  end

  ICONS = {
    'search' => 'fa-chart-line text-blue-500',
    'static_text' => 'fa-paragraph text-pink-500'
  }.freeze

  def widget_icon(widget_type)
    icon_class = ICONS[widget_type] || 'fa-image text-cyan-500'
    content_tag(:i, '', class: "fa #{icon_class} mr-2 text-xl")
  end

  private

  def to_widget_alpine_class(classes)
    "{ #{classes.map { |t, c| "#{c.to_json}: #{t.nil? ? 'true' : "widget_type === #{t.to_json}"}" }.join(', ')} }"
  end
end
