class Permission
  class << self
    def all_resources
      %w[
        access_points
        connection_links
        calendars
        footnotes
        imports
        exports
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
      ]
    end

    def destructive_permissions_for(models)
      models.product(%w[create destroy update]).map do |model_action|
        model_action.join('.')
      end
    end

    def all_destructive_permissions
      destructive_permissions_for all_resources
    end

    def base
      all_destructive_permissions + %w[sessions.create workbenches.update]
    end

    def extended
      permissions = base

      %w[purchase_windows exports].each do |resources|
        actions = %w[edit update create destroy]
        actions.each do |action|
          permissions << "#{resources}.#{action}"
        end
      end

      permissions << 'calendars.share'
    end

    def referentials
      permissions = []
      %w[stop_areas stop_area_providers lines companies networks].each do |resources|
        actions = %w[edit update create]
        actions << (%w[stop_areas lines].include?(resources) ? 'change_status' : 'destroy')

        actions.each do |action|
          permissions << "#{resources}.#{action}"
        end
      end
      permissions
    end

    def merges_rollback
      ['merges.rollback']
    end

    def full
      extended + referentials + merges_rollback
    end
  end
end
