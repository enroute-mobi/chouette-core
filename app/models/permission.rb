class Permission
  class << self
    def full
      (extended + referentials + user_permissions).uniq
    end

    def workgroup_permissions
      destructive_permissions_for %w[workgroups]
    end

    private

    def all_resources
      %w[
        access_points
        aggregates
        api_keys
        calendars
        compliance_check_sets
        compliance_control_blocks
        compliance_control_sets
        compliance_controls
        connection_links
        exports
        footnotes
        imports
        journey_patterns
        merges
        publication_api_keys
        publication_apis
        publication_setups
        referentials
        routes
        routing_constraint_zones
        shapes
        stop_area_routing_constraints
        stop_area_entrances
        time_tables
        vehicle_journeys
        workbenches
        notification_rules
      ]
    end

    def destructive_permissions_for(models)
      models.product( %w{create destroy update} ).map{ |model_action| model_action.join('.') }
    end

    def read_permissions_for(models)
      models.product( %w{create destroy update} ).map{ |model_action| model_action.join('.') }
    end

    def all_destructive_permissions
      destructive_permissions_for( all_resources )
    end

    def user_permissions
      destructive_permissions_for %w[users]
    end

    def base
      all_destructive_permissions + %w{sessions.create workbenches.update}
    end

    def extended
      permissions = base

      %w{exports}.each do |resources|
        actions = %w{edit update create destroy}
        actions.each do |action|
          permissions << "#{resources}.#{action}"
        end
      end

      permissions << "calendars.share"
      permissions << "merges.rollback"
      permissions << "aggregates.rollback"
      permissions << "api_keys.index"
      permissions << "workgroups.update"
      permissions << "referentials.flag_urgent"
      permissions << "stop_area_referentials.update"
    end

    def referentials
      permissions = []
      %w{stop_areas stop_area_providers lines companies networks line_notices}.each do |resources|
        actions = %w{edit update create}
        if resources == 'lines'
          actions << "update_activation_dates"
        elsif resources == 'stop_areas'
          actions << "change_status"
        else
          actions << "destroy"
        end

        actions.each do |action|
          permissions << "#{resources}.#{action}"
        end
      end
      permissions
    end
  end

  class Profile
    @profiles = HashWithIndifferentAccess.new

    DEFAULT_PROFILE = :custom

    class << self
      def profile(name, permissions)
        @profiles[name] = permissions.sort
      end

      def each &block
        all.each &block
      end

      def all
        @profiles.keys.map(&:to_sym)
      end

      def all_i18n(include_default=true)
        keys = @profiles.keys
        keys << DEFAULT_PROFILE if include_default
        keys.map {|p| ["permissions.profiles.#{p}.name".t, p.to_s]}
      end

      def permissions_for(profile_name)
        @profiles[profile_name]
      end

      def profile_for(permissions)
        return DEFAULT_PROFILE unless permissions

        sorted = permissions.sort

        each do |profile|
          return profile if permissions_for(profile) == sorted
        end

        DEFAULT_PROFILE
      end

      def update_users_permissions
        Profile.each do |profile|
          User.where(profile: profile).update_all permissions: Permission::Profile.permissions_for(profile)
        end
      end

      def set_users_profiles
        User.where(profile: nil).find_each {|u| u.update profile: Permission::Profile.profile_for(u.permissions)}
      end
    end

    profile :admin, Permission.full
    profile :editor, Permission.full.grep_v(/^users/)
    profile :visitor, %w{sessions.create}
  end
end
