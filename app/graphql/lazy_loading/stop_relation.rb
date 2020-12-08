module LazyLoading
  class StopRelation
    def initialize(query_ctx, stop_relation_id)
      @stop_relation_id = stop_relation_id
      # Initialize the loading state for this query or get the previously-initiated state
      @lazy_state = query_ctx[:lazy_find_stop_relation] ||= {
        pending_ids: Set.new,
        loaded_ids: {},
      }
      # Register this ID to be loaded later:
      @lazy_state[:pending_ids] << stop_relation_id
    end

    # Return the loaded record, hitting the database if needed
    def stop_relation
      # Check if the record was already loaded:
      loaded_record = @lazy_state[:loaded_ids][@stop_relation_id]
      if loaded_record
        # The pending IDs were already loaded so return the result of that previous load
        loaded_record
      else
        # The record hasn't been loaded yet, so hit the database with all pending IDs
        pending_ids = @lazy_state[:pending_ids].to_a
        stop_areas = Chouette::StopArea.where(id: pending_ids)

        # Fill and clean the map
        stop_areas.each { |stop| @lazy_state[:loaded_ids][stop.id] = stop }
        @lazy_state[:pending_ids].clear

        # Now, get the matching stop_areas from the loaded result:
        @lazy_state[:loaded_ids][@stop_relation_id]
      end
    end
  end
end
