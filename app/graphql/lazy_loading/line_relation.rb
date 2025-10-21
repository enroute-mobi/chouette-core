module LazyLoading
  class LineRelation
    def initialize(query_ctx, line_relation_id)
      @line_relation_id = line_relation_id
      # Initialize the loading state for this query or get the previously-initiated state
      @lazy_state = query_ctx[:lazy_find_line_relation] ||= {
        pending_ids: Set.new,
        loaded_ids: {},
      }
      # Register this ID to be loaded later:
      @lazy_state[:pending_ids] << line_relation_id
    end

    # Return the loaded record, hitting the database if needed
    def line_relation
      # Check if the record was already loaded:
      loaded_record = @lazy_state[:loaded_ids][@line_relation_id]
      if loaded_record
        # The pending IDs were already loaded so return the result of that previous load
        loaded_record
      else
        # The record hasn't been loaded yet, so hit the database with all pending IDs
        pending_ids = @lazy_state[:pending_ids].to_a
        lines = Chouette::Line.where(id: pending_ids)

        # Fill and clean the map
        lines.each { |line| @lazy_state[:loaded_ids][line.id] = line }
        @lazy_state[:pending_ids].clear

        # Now, get the matching lines from the loaded result:
        @lazy_state[:loaded_ids][@line_relation_id]
      end
    end
  end
end
