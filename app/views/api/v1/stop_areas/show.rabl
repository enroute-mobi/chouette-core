object @stop_area
extends "api/v1/trident_objects/show"

[:name, :area_type, :nearest_topic_name, :registration_number,
  :longitude, :latitude, :long_lat_type,
  :country_code, :street_name, :projection_x, :projection_y, :projection, :comment
].each do |attr|
  attributes attr, :unless => lambda { |m| m.send( attr).nil?}
end

node :parent do |stop_area|
  partial("api/v1/stop_areas/short_description", :object => stop_area.parent)
end unless root_object.parent.nil?
