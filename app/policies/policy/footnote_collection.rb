# frozen_string_literal: true

module Policy
  class FootnoteCollection < Base
    authorize_by Strategy::Referential
    authorize_by Strategy::Permission
    permission_exception :update_all, 'footnotes.update'

    def update_all?
      around_can(:update_all) { true }
    end
    alias edit_all? update_all?
  end
end
