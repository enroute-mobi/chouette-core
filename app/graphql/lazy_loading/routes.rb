module LazyLoading
  class Routes
    def initialize(query_ctx, line_id)
      @line_id = line_id
      # Initialize the loading state for this query or get the previously-initiated state
      @lazy_state = query_ctx[:lazy_find_routes] ||= {
        pending_ids: Set.new,
        loaded_ids: {},
      }
      # Register this ID to be loaded later:
      @lazy_state[:pending_ids] << line_id
    end

    # Return the loaded record, hitting the database if needed
    def routes
      # Check if the record was already loaded:
      loaded_records = @lazy_state[:loaded_ids][@line_id]
      if loaded_records
        # The pending IDs were already loaded so return the result of that previous load
        loaded_records
      else
        # The record hasn't been loaded yet, so hit the database with all pending IDs
        pending_ids = @lazy_state[:pending_ids].to_a
        routes = Chouette::Route.where(line_id: pending_ids)

        # Fill and clean the map
        routes.each do |route|
          @lazy_state[:loaded_ids][route.line_id] ||= []
          @lazy_state[:loaded_ids][route.line_id] << route
        end
        @lazy_state[:pending_ids].clear

        # Now, get the matching routes from the loaded result:
        @lazy_state[:loaded_ids][@line_id]
      end
    end
  end
end