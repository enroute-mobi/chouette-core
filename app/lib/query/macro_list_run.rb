module Query
  class MacroListRun < Base
    def name(value)
      where(value, :matches, :name)
    end
  end
end
