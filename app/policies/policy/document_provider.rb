# frozen_string_literal: true

module Policy
  class DocumentProvider < Base
    authorize_by Strategy::Permission
    authorize_by Strategy::NotUsed, only: %i[destroy]

    protected

    def _create?(resource_class)
      [
        ::Document
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
