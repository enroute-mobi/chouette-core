# frozen_string_literal: true

module Policy
  module Strategy
    class NotCurrentAndSuccessful < Strategy::Base
      def apply(_action, *_args)
        !resource.current? && resource.successful?
      end
    end
  end
end
