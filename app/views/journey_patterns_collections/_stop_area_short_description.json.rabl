%i[
  id
  name
  city_name
  zip_code
  area_type
  kind
  longitude
  latitude
].each do |attr|
  attributes attr, unless: ->(m) { m.send(attr).nil? }
end

attributes objectid: :object_id
attributes :object_version

unless root_object.parent.nil?
  node :parent_object_id do |stop_area|
    stop_area.parent.objectid
  end
end
