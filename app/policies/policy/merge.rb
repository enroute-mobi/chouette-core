# frozen_string_literal: true

module Policy
  class Merge < Base
    authorize_by Strategy::NotCurrentAndSuccessful
    authorize_by Strategy::Permission

    def rollback?
      around_can(:rollback) { true }
    end
  end
end
