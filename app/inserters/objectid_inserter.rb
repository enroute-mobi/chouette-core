class ObjectidInserter

  attr_reader :target
  def initialize(target, _options = {})
    @target = target
  end

  def objectid_formatter
    @objectid_formatter ||= target.objectid_formatter
  end

  def insert(model, options = {})
    return unless support_objectid?(model)
    return unless model.objectid.nil?

    model.objectid = new_objectid(model)
  end

  def support_objectid?(model)
    model.respond_to?(:objectid)
  end

  def new_objectid(model)
    objectid_formatter.objectid(model).to_s
  end
end
