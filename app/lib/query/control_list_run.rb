module Query
  class ControlListRun < Base
    def name(value)
      where(value, :matches, :name)
    end
  end
end
