# frozen_string_literal: true

module Policy
  class Workgroup < Base
    authorize_by Strategy::Permission, only: %i[create update destroy]

    alias edit_aggregate? update?
    alias edit_merge? update?
    alias edit_transport_modes? update?

    alias setup_deletion? destroy?
    alias remove_deletion? destroy?

    # FIXME Required only by Workgroup decorator and associated action :-/
    def add_workbench?
      around_can(:add_workbench) { create?(::Workbench) }
    end

    protected

    def _create?(resource_class) # rubocop:disable Metrics/MethodLength
      if [
        ::Aggregate,
        ::PublicationSetup
      ].include?(resource_class)
        update?
      else
        [
          ::DocumentType,
          ::Workbench,
          ::ProcessingRule::Workgroup,
          ::PublicationApi
        ].include?(resource_class)
      end
    end

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
