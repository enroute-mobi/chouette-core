module LazyLoading
  class ServiceCounts
    def initialize(query_ctx, line_id, from, to)
      @line_id = line_id
      @from = from
      @to = to
      # Initialize the loading state for this query or get the previously-initiated state
      @lazy_state = query_ctx[:lazy_find_line_service_counts] ||= {
        pending_ids: Set.new,
        loaded_ids: {},
      }
      # Register this ID to be loaded later:
      @lazy_state[:pending_ids] << line_id
    end

    # Return the loaded record, hitting the database if needed
    def service_counts
      # If filtering params have been provided, then the cache isn't used
      if (@from || @to)
        if (@from && @to)
          result = Stat::JourneyPatternCoursesByDate.for_lines(@line_id).between(@from.to_date, @to.to_date).select('*')
        elsif @from
          result = Stat::JourneyPatternCoursesByDate.for_lines(@line_id).after(@from.to_date).select('*')
        elsif @to
          result = Stat::JourneyPatternCoursesByDate.for_lines(@line_id).before(@to.to_date).select('*')
        end
        # Group result by date (in case of multiple routes), return the sum of every serviceCount occuring the same date
        return result.group_by(&:date).values.map do |el|
          el.first.assign_attributes(count:el.pluck(:count).reduce(:+))
          el.first
        end

      end

      loaded_records = @lazy_state[:loaded_ids][@line_id]&.values
      if loaded_records
        # The pending IDs were already loaded so return the result of that previous load
        loaded_records
      else
        # The record hasn't been loaded yet, so hit the database with all pending IDs
        pending_ids = @lazy_state[:pending_ids].to_a
        service_counts = Stat::JourneyPatternCoursesByDate.for_lines(pending_ids).select('*')

        # Fill and clean the map
        service_counts.each do |service_count|
          @lazy_state[:loaded_ids][service_count.line_id] ||= {}

          if @lazy_state[:loaded_ids][service_count.line_id][service_count.date]
            @lazy_state[:loaded_ids][service_count.line_id][service_count.date].count = @lazy_state[:loaded_ids][service_count.line_id][service_count.date].count + service_count.count
          else
            @lazy_state[:loaded_ids][service_count.line_id][service_count.date] = service_count
          end
        end
        @lazy_state[:pending_ids].clear
        # Now, get the matching lines from the loaded result:
        @lazy_state[:loaded_ids][@line_id].values
      end
    end
  end
end
