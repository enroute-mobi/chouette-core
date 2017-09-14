module Stif
  module PermissionTranslator extend self

    def translate(sso_extra_permissions)
      sso_extra_permissions
        .sort
        .flat_map(&method(:extra_permission_translation))
        .uniq
    end

    private

    def all_destructive_permissions
      destructive_permissions_for( all_resources )
    end

    def all_resources
      %w[
        api_keys
        access_points
        connection_links calendars
        footnotes
        journey_patterns
        referentials routes routing_constraint_zones
        time_tables
        vehicle_journeys
        api_keys
      ]
    end

    def destructive_permissions_for(models)
      @__destructive_permissions_for__ ||=
        models.product( %w{create destroy update} ).map{ |model_action| model_action.join('.') }
    end

    def extra_permission_translation extra_permission
      translation_table.fetch(extra_permission, [])
    end

    def translation_table
      {
        "boiv:read-offer" => %w{sessions:create},
        "boiv:edit-offer" => all_destructive_permissions + %w{sessions:create},
      }
    end
  end
end
