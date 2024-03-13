# frozen_string_literal: true

module Policy
  class Source < Base
    authorize_by Strategy::Permission
    permission_exception :update_workgroup_providers, 'imports.update_workgroup_providers'

    def retrieve?
      around_can(:retrieve) { true }
    end

    def update_workgroup_providers?
      around_can(:update_workgroup_providers) { true }
    end

    protected

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
