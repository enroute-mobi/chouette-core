module Query
  class MacroListRun < Query::Operation
    def name(value)
      where(value, :matches, :name)
    end
  end
end
