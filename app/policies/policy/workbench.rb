# frozen_string_literal: true

module Policy
  class Workbench < Base
    authorize_by Strategy::Permission

    protected

    def _create?(resource_class)
      [
        ::Referential,
        ::DocumentProvider,
        ::Document,
        ::Calendar
      ].include?(resource_class)
    end

    def _update?
      true
    end

    # TODO Enable workbench deletion / creation from workgroup admin section
    # def _destroy?
    #   update?
    # end
  end
end
