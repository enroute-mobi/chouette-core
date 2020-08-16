module LazyLoading
  class Lines
    def initialize(query_ctx, stop_area_id)
      @stop_area_id = stop_area_id
      # Initialize the loading state for this query or get the previously-initiated state
      @lazy_state = query_ctx[:lazy_find_liness] ||= {
        pending_ids: Set.new,
        loaded_ids: {},
      }
      # Register this ID to be loaded later:
      @lazy_state[:pending_ids] << stop_area_id
    end

    # Return the loaded record, hitting the database if needed
    def lines
      # Check if the record was already loaded:
      loaded_records = @lazy_state[:loaded_ids][@stop_area_id]
      if loaded_records
        # The pending IDs were already loaded so return the result of that previous load
        loaded_records
      else
        # The record hasn't been loaded yet, so hit the database with all pending IDs
        pending_ids = @lazy_state[:pending_ids].to_a
        lines = Chouette::Line.joins(:routes => [:stop_points => :stop_area])
          .where(:stop_areas => {:id => pending_ids})
          .select('lines.id', 'line_referential_id', 'lines.name', 'lines.objectid', 'stop_areas.id as stop_area_id')

        # Fill and clean the map
        lines.each do |stop|
          @lazy_state[:loaded_ids][stop.stop_area_id] ||= []
          @lazy_state[:loaded_ids][stop.stop_area_id] << stop
        end
        @lazy_state[:pending_ids].clear
        @lazy_state[:loaded_ids].transform_values! { |v| v.uniq } # The request returns the same stop multiple times

        # Now, get the matching lines from the loaded result:
        @lazy_state[:loaded_ids][@stop_area_id]
      end
    end
  end
end