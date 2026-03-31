# frozen_string_literal: true

module Scope
  class Workgroup < Delegator
    alias workgroup object

    SUPPORTED = %i[
      lines
      line_groups
      line_notices
      companies
      networks
      booking_arrangements
      stop_areas
      stop_area_groups
      entrances
      connection_links
      shapes
      point_of_interests
      service_facility_sets
      accessibility_assessments
      fare_zones
      line_routing_constraint_zones
      document_memberships
      documents
      contracts
    ].freeze
  end
end
