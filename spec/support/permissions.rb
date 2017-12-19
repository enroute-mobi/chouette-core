module Support
  module Permissions extend self

    def all_permissions
      @__all_permissions__ ||= _all_destructive_permissions << 'sessions.create'
    end

    def all_stif_permissions
      @__all_stif_permissions__ ||= _destructive_permissions << 'sessions.create'
    end


    private

    def _all_destructive_permissions
      _all_permitted_resources.product( %w{create destroy update} ).map{ |model_action| model_action.join('.') }
    end

    def _destructive_permissions
      _permitted_resources.product( %w{create destroy update} ).map{ |model_action| model_action.join('.') }
    end

    def _all_permitted_resources
      %w[
        companies
        group_of_lines
        lines
        networks
        stop_areas
      ] + _permitted_resources
    end
    def _permitted_resources
      %w[
        access_points
        api_keys
        calendars
        connection_links
        compliance_control_blocks
        compliance_control_sets
        compliance_controls
        compliance_check_sets
        footnotes
        imports
        journey_patterns
        referentials
        routes
        routing_constraint_zones
        time_tables
        vehicle_journeys
      ]
    end
  end
end
