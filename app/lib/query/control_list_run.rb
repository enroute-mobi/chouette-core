module Query
  class ControlListRun < Query::Operation
    def name(value)
      where(value, :matches, :name)
    end
  end
end
