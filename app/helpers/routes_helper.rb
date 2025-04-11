module RoutesHelper

  def line_formatted_name( line)
    return line.published_name if line.number.blank?
    "#{line.published_name} [#{line.number}]"
  end

  def fonticon_wayback(wayback)
    if wayback == 'outbound'
      return '<i class="fa fa-arrow-right"></i>'.html_safe
    else
      return '<i class="fa fa-arrow-left"></i>'.html_safe
    end
  end

  def input_opposite_route_id_css(route, way)
    css = ['opposite_route', way]
    css << 'hidden' if route.wayback.send("#{way}?")
    css
  end

end
