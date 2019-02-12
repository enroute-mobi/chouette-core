class Chouette::Netex::Resource
  include Chouette::Netex::Helpers

  def initialize(resource, collection=nil)
    @resource = resource
    @collection = collection
  end

  def self.reset_cache
    @cache = nil
  end

  def self.set_cache key, val
    @cache ||= {}
    @cache[key] = val
  end

  def self.get_cache key
    @cache ||= {}
    @cache[key]
  end

  def resource
    @resource
  end

  def collection
    @collection
  end

  def to_xml(builder)
    @builder = builder
    build_xml
    @builder = nil
  end

  def attributes_mapping(mapping=nil, target=nil)
    mapping ||= attributes
    target ||= resource

    mapping.each do |tag, attr|
      val = attr_to_val(attr, target)
      @builder.send(tag, val) if val.present?
    end
  end

  def default_resource_metas
    {
      version: :any,
      created: format_time(resource.created_at),
      changed: format_time(resource.updated_at),
      id: resource.objectid
    }
  end

  def resource_metas
    default_resource_metas
  end

  def custom_field_values(source=nil)
    source ||= resource

    source.custom_fields.values.select{ |v| v.value.present? }.map do |v|
      [v.code, v.display_value]
    end
  end

  def custom_fields_as_key_values(source=nil)
    custom_field_values(source).each do |k, v|
      key_value(k, v)
    end
  end

  def attr_to_val(attr, target=nil)
    target ||= resource

    if attr.is_a?(Proc)
      val = attr.call
    elsif attr.is_a?(Symbol)
      val = target.send(attr)
    else
      val = attr
    end
  end

  def key_value(name, attr)
    val = attr_to_val(attr)
    return unless val.present?

    @builder.KeyValue do
      @builder.Key name
      @builder.Value val
    end
  end

  def ref(name, val)
    return unless val.present?

    @builder.send(name, ref: val)
  end

  def node_if_content name, &block
    built = @builder.send name, &block
    node = built.instance_variable_get("@node")
    node.remove if node.children.count.zero?
  end

  def node_with_attributes_mapping name, attributes
    node_if_content name do
      attributes_mapping(attributes)
    end
  end
end
