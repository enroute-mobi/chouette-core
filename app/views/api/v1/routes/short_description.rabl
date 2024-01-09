object @route
extends "api/v1/trident_objects/short_description"
[ :name, :published_name, :number, :direction, :wayback].each do |attr|
  attributes attr, :unless => lambda { |m| m.send( attr).nil?}
end
child :stop_points => :stop_points do |stop_points|
  node do |stop_point|
    partial("api/v1/stop_areas/short_description", :object => stop_point.stop_area).merge(position: stop_point.position)
  end
end