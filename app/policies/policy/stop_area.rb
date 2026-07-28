# frozen_string_literal: true

module Policy
  class StopArea < Base
    prepend ::Policy::Documentable

    authorize_by Strategy::StopAreaProvider
    authorize_by Strategy::Permission

    protected

    def _update?
      !resource.stop_area_provider.disable_stop_area_manual_edit?
    end

    def _destroy?
      true
    end
  end
end
