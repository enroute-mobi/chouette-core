object @route

attributes :id, :name, :wayback

child :stop_points, :object_root => false do
  attributes :id, :stop_area_id
  [:longitude, :latitude].each do |attr|
    node(attr) { |sp| sp.stop_area.send(attr) }
  end
end