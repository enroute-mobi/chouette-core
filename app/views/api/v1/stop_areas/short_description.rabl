object @stop_area
extends "api/v1/trident_objects/short_description"
[:id, :name, :city_name, :zip_code, :area_type, :kind, :longitude, :latitude, :long_lat_type].each do |attr|
    attributes attr, :unless => lambda { |m| m.send( attr).nil?}
end
node(:parent_object_id) do |stop_area|
  stop_area.parent.objectid
end unless root_object.parent.nil?