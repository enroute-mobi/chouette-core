module Query
  class Document < Base
    def name(value)
      where(value, :matches, :name)
    end
  end
end
