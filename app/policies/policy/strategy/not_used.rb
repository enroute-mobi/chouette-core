# frozen_string_literal: true

module Policy
  module Strategy
    class NotUsed < Strategy::Base
      def apply(_action, *_args)
        !resource.used?
      end
    end
  end
end
