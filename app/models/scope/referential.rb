# frozen_string_literal: true

module Scope
  class Referential < Delegator
    alias referential object

    SUPPORTED = %i[
      routes
      stop_points
      journey_patterns
      journey_pattern_stop_points
      vehicle_journeys
      vehicle_journey_at_stops
      time_tables
      time_table_periods
      time_table_dates
      service_counts
      footnotes
      routing_constraint_zones
      metadatas
    ].freeze

    collection :organisations do
      # TODO: - distinct is on metadatas, not on organisations
      #       - we get all ids while we can simply make the request

      # Find organisations which provided metadata in the referential
      # Only works for merged/aggregated datasets
      organisation_ids = global_scope.metadatas.joins(referential_source: :organisation)
                                     .distinct
                                     .pluck(Arel.sql("#{::Organisation.quoted_table_name}.id"))

      # Use the Referential owner in fallback
      organisation_ids = [referential.organisation_id] if organisation_ids.empty?

      referential.workgroup.organisations.where(id: organisation_ids)
    end

    attribute :validity_period do
      ::Period.for_range(referential.validity_period)
    end
  end
end
