require 'ostruct'

module MetadataSupport
  extend ActiveSupport::Concern

  included do
    class << self
      def has_metadata?
        !!@has_metadata
      end

      def has_metadata opts={}
        @has_metadata = true

        define_method :metadata do
          attr_name = opts[:attr_name] || :metadata
          @wrapped_metadata ||= begin
            wrapped = MetadataSupport::MetadataWrapper.new self.read_attribute(attr_name)
            wrapped.attribute_name = attr_name
            wrapped.owner = self
            wrapped
          end
        end

        define_method :metadata= do |val|
          @wrapped_metadata = nil
          super val
        end

        define_method :set_metadata! do |name, value|
          self.metadata.send "#{name}=", value
          self.update_column :metadata, self.metadata.as_json
        end
      end
    end
  end

  def has_metadata?
    self.class.has_metadata?
  end

  def merge_metadata_from source
    return unless source.has_metadata?
    source_metadata = source.metadata
    res = {}
    self.metadata.each do |k, v|
      unless self.metadata.is_timestamp_attr?(k)
        ts = self.metadata.timestamp_attr(k)
        if source_metadata[ts] && self.metadata[ts] && source_metadata[ts] > self.metadata[ts]
          res[k] = source_metadata[k]
        else
          res[k] = v
        end
      end
    end
    self.metadata = res
    self
  end

  class MetadataWrapper < OpenStruct
    attr_accessor :attribute_name, :owner

    def is_timestamp_attr? name
      name =~ /_updated_at$/
    end

    def timestamp_attr name
      "#{name}_updated_at".to_sym
    end

    def as_json *args
      @table.as_json *args
    end

    def method_missing(mid, *args)
      out = super(mid, *args)
      owner.send :write_attribute, attribute_name, @table
      out = out&.to_time if args.length == 0 && is_timestamp_attr?(mid)
      out
    end

    def each
      @table.each do |k,v|
        yield k, v
      end
    end

    def delete(key)
      @table.delete(key)
    end

    def new_ostruct_member! name
      @_initialized_members ||= []
      unless is_timestamp_attr?(name)
        timestamp_attr_name = timestamp_attr(name)
      end

      name = name.to_sym
      unless @_initialized_members.include?(name)
        @_initialized_members << name
        if timestamp_attr_name
          define_singleton_method(timestamp_attr_name) { @table[timestamp_attr_name]&.to_time }
          define_singleton_method(name) { @table[name] }
        else
          # we are defining an accessor for a timestamp
          define_singleton_method(name) { @table[name]&.to_time }
        end

        define_singleton_method("#{name}=") do |x|
          modifiable?[timestamp_attr_name] = Time.now if timestamp_attr_name
          modifiable?[name] = x
          owner.send :write_attribute, attribute_name, @table
        end
        modifiable?[timestamp_attr_name] = Time.now if timestamp_attr_name
      end
      name
    end
  end
end
