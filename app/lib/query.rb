module Query
  def self.for(klass)
    "Query::#{klass.name.demodulize}".constantize
  end
end