module Support
  module Permissions extend self

    def all_permissions
      @__all_permissions__ ||= _destructive_permissions + %w{sessions.create}
    end

    private

    def _destructive_permissions
      _permitted_resources.product( %w{create destroy update} ).map{ |model_action| model_action.join('.') }
    end

    def _permitted_resources
      %w[
        connection_links
        calendars
        footnotes
        exports
        imports
        merges
        journey_patterns
        referentials
        routes
        routing_constraint_zones
        time_tables
        vehicle_journeys
        api_keys
        compliance_controls
        compliance_control_sets
        compliance_control_blocks
        compliance_check_sets
        workbenches
        workgroups
        shapes
      ]
    end
  end
end
