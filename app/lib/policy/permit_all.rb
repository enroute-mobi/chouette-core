# frozen_string_literal: true

module Policy
  # Policy which authorizes any action
  class PermitAll < Base
    protected

    def _can?(_action, *_args)
      true
    end
  end
end
