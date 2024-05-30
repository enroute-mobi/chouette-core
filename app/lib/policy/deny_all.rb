# frozen_string_literal: true

module Policy
  class DenyAll < Base
    include Singleton

    def initialize
      super(nil)
    end
  end
end
