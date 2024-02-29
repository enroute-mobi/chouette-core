module LazyLoading
  class RouteStopPoints
    def initialize(query_ctx, route_id)
      @route_id = route_id
      # Initialize the loading state for this query or get the previously-initiated state
      @lazy_state = query_ctx[:lazy_find_route_stop_points] ||= {
        pending_ids: Set.new,
        loaded_ids: {},
      }
      # Register this ID to be loaded later:
      @lazy_state[:pending_ids] << route_id
    end

    # Return the loaded record, hitting the database if needed
    def stop_points
      # Check if the record was already loaded:
      loaded_records = @lazy_state[:loaded_ids][@route_id]
      if loaded_records
        # The pending IDs were already loaded so return the result of that previous load
        loaded_records
      else
        # The record hasn't been loaded yet, so hit the database with all pending IDs
        pending_ids = @lazy_state[:pending_ids].to_a
        stop_points = Chouette::StopPoint.where(route_id: pending_ids)

        # Fill and clean the map
        stop_points.each do |stop|
          @lazy_state[:loaded_ids][stop.route_id] ||= []
          @lazy_state[:loaded_ids][stop.route_id] << stop
        end
        @lazy_state[:pending_ids].clear

        # Now, get the matching stop_areas from the loaded result:
        @lazy_state[:loaded_ids][@route_id]
      end
    end
  end
end
