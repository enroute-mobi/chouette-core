module LazyLoading
  class Children
    def initialize(query_ctx, stop_id)
      @stop_id = stop_id
      # Initialize the loading state for this query or get the previously-initiated state
      @lazy_state = query_ctx[:lazy_find_children] ||= {
        pending_ids: Set.new,
        loaded_ids: {},
      }
      # Register this ID to be loaded later:
      @lazy_state[:pending_ids] << stop_id
    end

    # Return the loaded record, hitting the database if needed
    def children
      # Check if the record was already loaded:
      loaded_records = @lazy_state[:loaded_ids][@stop_id]
      if loaded_records
        # The pending IDs were already loaded so return the result of that previous load
        loaded_records
      else
        # The record hasn't been loaded yet, so hit the database with all pending IDs
        pending_ids = @lazy_state[:pending_ids].to_a
        children = Chouette::StopArea.where(parent_id: pending_ids)

        # Fill and clean the map
        children.each do |stop|
          @lazy_state[:loaded_ids][stop.parent_id] ||= []
          @lazy_state[:loaded_ids][stop.parent_id] << stop
        end
        @lazy_state[:pending_ids].clear

        # Now, get the matching children from the loaded result:
        @lazy_state[:loaded_ids][@stop_id]
      end
    end
  end
end
