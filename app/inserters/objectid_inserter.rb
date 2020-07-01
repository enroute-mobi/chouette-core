class ObjectidInserter

  attr_reader :target
  def initialize(target, options = {})
    @target = target
  end

  def objectid_formatter
    @objectid_formatter ||= target.objectid_formatter
  end

  def insert(model)
    if model.respond_to?(:objectid) && model.objectid.nil?
      model.objectid = objectid_formatter.objectid(model).to_s
    end
  end

end
