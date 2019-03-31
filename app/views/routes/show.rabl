object @route

attributes :id, :name, :wayback

child :stop_points, :object_root => false do
  attributes :id, :stop_area_id, :for_boarding, :for_alighting
  [:name, :city_name, :zip_code, :registration_number, :area_type, :comment, :stop_area_referential_id, :longitude, :latitude].each do |attr|
    node(attr) { |sp| sp.stop_area.send(attr) }
  end
  node(:short_name) do |sp|
    truncate(sp.stop_area.name, :length => 30) || ""
  end
end