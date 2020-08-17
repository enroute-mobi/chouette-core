module ShapesHelper

  def kml_representation(shape)
    result = "<Placemark id=\"#{shape.uuid}\">\n"
    result += "<name>#{shape.name}</name>"
    result += "<LineString>\n"
    result += "<coordinates>\n"
    result += shape.geometry.points.map { |p| "#{p.x},#{p.y}" }.join(" ")
    result += "</coordinates>\n"
    result += "</LineString>\n"
    result += "</Placemark>"
  end
  
end
