# frozen_string_literal: true

module Policy
  class DocumentType < Base
    authorize_by Strategy::Permission
    # A DocumentType should not be destroyed if they are linked to a document (mandatory attribute)
    authorize_by Strategy::NotUsed, only: %i[destroy]

    protected

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
