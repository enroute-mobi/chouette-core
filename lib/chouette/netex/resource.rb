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

  def attributes_mapping(builder, mapping=nil)
    mapping ||= attributes

    mapping.each do |tag, attr|
      builder.send(tag, attr_to_val(attr))
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

  def custom_fields_as_key_values(builder, source=nil)
    custom_field_values(source).each do |k, v|
      key_value(k, v, builder)
    end
  end

  def attr_to_val(attr)
    if attr.is_a?(Proc)
      val = attr.call
    elsif attr.is_a?(Symbol)
      val = resource.send(attr)
    else
      val = attr
    end
  end

  def key_value(name, attr, builder)
    val = attr_to_val(attr)

    if val.present?
      builder.KeyValue do
        builder.Key name
        builder.Value val
      end
    end
  end
end
