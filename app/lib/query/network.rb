# frozen_string_literal: true

module Query
  class Network < Base
    def name(value)
      where(value, :matches, :name)
    end
  end
end
