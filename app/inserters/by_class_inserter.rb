class ByClassInserter

  def insert(model, options = {})
    self.for(model.class).insert(model, options)
  end

  # Hash of singleton inserters
  def inserters
    @inserters ||= Hash.new { |h,k| h[k] = new_inserter_for(k) }
  end

  def new_inserter_for(model_class)
    self.class.insert_class_for(model_class).new(model_class, self)
  end

  # Either a model has a dedicated inserter, or use the base inserter class as a fallback
  def self.insert_class_for(model_class)
    "#{name}::#{model_class.name.demodulize}".constantize
  rescue NameError
    "#{name}::Base".constantize
  end

  # Each model has one instanciated inserter
  def for(model_class)
    inserters[model_class]
  end

  def flush
    inserters.values.each(&:flush)
  end

end
