# frozen_string_literal: true

module LazyLoading
  class Documents
    def initialize(query_ctx, documentable)
      @documentable_type = documentable.class.sti_name
      @documentable_id = documentable.id
      # Initialize the loading state for this query or get the previously-initiated state
      @lazy_state = query_ctx[:lazy_find_documents] ||= {
        pending_ids: Hash.new { |h, k| h[k] = Set.new },
        loaded: false,
        loaded_ids: nil
      }
      # Register this ID to be loaded later:
      @lazy_state[:pending_ids][@documentable_type] << @documentable_id
    end

    # Return the loaded record, hitting the database if needed
    def documents
      # Check if the record was already loaded:
      if @lazy_state[:loaded]
        # The pending IDs were already loaded so return the result of that previous load
        loaded_records
      else
        # The record hasn't been loaded yet, so hit the database with all pending IDs
        pending_ids = @lazy_state[:pending_ids].flat_map { |type, ids| ids.map { |id| [type, id] } }
        document_memberships = ::DocumentMembership.where([:documentable_type, :documentable_id] => pending_ids)
                                                   .includes(:document)
        @lazy_state[:loaded_ids] = document_memberships.group_by(&:documentable_type)
                                                       .transform_values do |dms|
                                                         dms.group_by(&:documentable_id).transform_values do |dms|
                                                           dms.map(&:document)
                                                         end
                                                       end

        @lazy_state[:pending_ids].clear
        @lazy_state[:loaded] = true

        # Now, get the matching documents from the loaded result:
        loaded_records
      end
    end

    private

    def loaded_records
      return [] unless @lazy_state[:loaded_ids]

      by_documentable_type = @lazy_state[:loaded_ids][@documentable_type]
      return [] unless by_documentable_type

      by_documentable_id = by_documentable_type[@documentable_id]
      return [] unless by_documentable_id

      by_documentable_id
    end
  end
end
