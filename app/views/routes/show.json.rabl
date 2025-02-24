object @route

attributes :name, :published_name, :wayback, :opposite_route_id, :line_id

child :stop_points, object_root: false do |route|
  node do |stop_point|
    partial("routes/stop_points/show", object: stop_point)
  end
end
