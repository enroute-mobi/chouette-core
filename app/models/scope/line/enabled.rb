# frozen_string_literal: true

module Scope
  module Line
    class Enabled < Base
      collection :lines do
        now = Date.current
        current_collection.active_between(now, now)
      end
    end
  end
end
