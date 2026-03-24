# frozen_string_literal: true

module Scope
  module StopArea
    class Enabled < Base
      collection :stop_areas do
        current_collection.where(deleted_at: nil)
      end
    end
  end
end
