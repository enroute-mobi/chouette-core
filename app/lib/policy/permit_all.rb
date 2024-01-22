# frozen_string_literal: true

module Policy
  # Policy which authorizes any action
  class PermitAll < Base
    def can?(_action)
      true
    end
  end
end
