# frozen_string_literal: true

module LazyLoading
  class DocumentType
    def initialize(query_ctx, object_id)
      @object_id = object_id
      # Initialize the loading state for this query or get the previously-initiated state
      @lazy_state = query_ctx[:lazy_find_document_type] ||= {
        pending_ids: Set.new,
        loaded_ids: {}
      }
      # Register this ID to be loaded later:
      @lazy_state[:pending_ids] << object_id
    end

    # Return the loaded record, hitting the database if needed
    def document_type
      # Check if the record was already loaded:
      loaded_record = @lazy_state[:loaded_ids][@object_id]
      if loaded_record
        # The pending IDs were already loaded so return the result of that previous load
        loaded_record
      else
        # The record hasn't been loaded yet, so hit the database with all pending IDs
        pending_ids = @lazy_state[:pending_ids].to_a
        document_types = ::DocumentType.where(id: pending_ids)

        # Fill and clean the map
        document_types.each { |document_type| @lazy_state[:loaded_ids][document_type.id] = document_type.short_name }
        @lazy_state[:pending_ids].clear

        # Now, get the matching document types from the loaded result:
        @lazy_state[:loaded_ids][@object_id]
      end
    end
  end
end
