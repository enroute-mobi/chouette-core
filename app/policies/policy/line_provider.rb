# frozen_string_literal: true

module Policy
  class LineProvider < Base
    authorize_by Strategy::Workbench, only: %i[update destroy]
    authorize_by Strategy::Permission
    authorize_by Strategy::NotUsed, only: %i[destroy]

    protected

    def _create?(resource_class)
      [
        ::Chouette::Company,
        ::Chouette::Line,
        ::Chouette::LineNotice,
        ::LineRoutingConstraintZone,
        ::Chouette::Network
      ].include?(resource_class)
    end

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
