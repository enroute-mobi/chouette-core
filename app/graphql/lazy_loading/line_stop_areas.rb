module LazyLoading
  class LineStopAreas
    def initialize(query_ctx, line_id)
      @line_id = line_id
      # Initialize the loading state for this query or get the previously-initiated state
      @lazy_state = query_ctx[:lazy_find_line_stop_areas] ||= {
        pending_ids: Set.new,
        loaded_ids: {},
      }
      # Register this ID to be loaded later:
      @lazy_state[:pending_ids] << line_id
    end

    # Return the loaded record, hitting the database if needed
    def stop_areas
      # Check if the record was already loaded:
      loaded_records = @lazy_state[:loaded_ids][@line_id]
      if loaded_records
        # The pending IDs were already loaded so return the result of that previous load
        loaded_records
      else
        # The record hasn't been loaded yet, so hit the database with all pending IDs
        pending_ids = @lazy_state[:pending_ids].to_a
        stop_areas = Chouette::StopArea.joins(:stop_points => [:route => :line])
          .where(:lines => {:id => pending_ids})
          .select('stop_areas.*', 'lines.id as line_id')

        # Fill and clean the map
        stop_areas.each do |stop|
          @lazy_state[:loaded_ids][stop.line_id] ||= []
          @lazy_state[:loaded_ids][stop.line_id] << stop
        end
        @lazy_state[:pending_ids].clear
        @lazy_state[:loaded_ids].transform_values! { |v| v.uniq } # The request returns the same stop multiple times

        # Now, get the matching stop_areas from the loaded result:
        @lazy_state[:loaded_ids][@line_id]
      end
    end
  end
end
