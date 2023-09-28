# frozen_string_literal: true

module Query
  class Workgroup < Base
    def name(value)
      where(value, :matches, :name)
    end
  end
end
