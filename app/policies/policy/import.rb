# frozen_string_literal: true

module Policy
  class Import < Base
    authorize_by Strategy::Permission, only: %i[update option_flag_urgent option_update_workgroup_providers]
    permission_exception :option_flag_urgent, 'referentials.flag_urgent'
    permission_exception :option_update_workgroup_providers, 'imports.update_workgroup_providers'

    # CHOUETTE-3346 moved from CHOUETTE-407
    # Example for the future - Ignore me
    # Include here ApiKey permissions in the future
    # if api_key && !api_key.has_permission?(permission)
    #   return false
    # end

    def option?(option_name)
      option_method = :"option_#{option_name}?"
      if methods.include?(option_method)
        send(option_method)
      else
        around_can(:option, option_name) do
          # By default, options don't require permission
          true
        end
      end
    end

    def option_flag_urgent?
      around_can(:option_flag_urgent) { true }
    end

    def option_update_workgroup_providers?
      around_can(:option_update_workgroup_providers) { true }
    end

    protected

    def _update?
      true
    end
  end
end
