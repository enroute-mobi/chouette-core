# frozen_string_literal: true

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
          @wrapped_metadata ||= MetadataSupport::MetadataWrapper.new(attr_name, self, read_attribute(attr_name))
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
    def initialize(attribute_name, owner, hash = nil)
      @attribute_name = attribute_name
      @owner = owner
      @_init = true
      super(hash)
      @_init = nil
    end
    attr_reader :attribute_name, :owner

    delegate :as_json, :each, to: :@table

    def []=(name, value)
      if @_init
        # If we are still in constructor, we:
        #   - do not write timestamp as it should be initialized from the hash
        #   - do not write attribute in record as the hash is very probably initialized from this very same attribute
        super
      else
        super.tap do
          @table[timestamp_attr(name)] = Time.zone.now unless is_timestamp_attr?(name)
          owner.send(:write_attribute, attribute_name, @table)
        end
      end
    end
    alias_method :set_ostruct_member_value!, :[]= # rubocop:disable Style/Alias
    private :set_ostruct_member_value!

    def is_timestamp_attr? name
      name =~ /_updated_at$/
    end

    def timestamp_attr name
      "#{name}_updated_at".to_sym
    end

    private

    def new_ostruct_member!(name) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      return if @table.key?(name) || is_method_protected!(name)

      if is_timestamp_attr?(name)
        attr_name = nil
        timestamp_attr_name = name
      else
        attr_name = name
        timestamp_attr_name = timestamp_attr(name)
      end

      if attr_name
        define_singleton_method!(attr_name) { @table[attr_name] }

        define_singleton_method("#{name}=") do |x|
          @table[name] = x
          @table[timestamp_attr_name] = Time.zone.now
          owner.send(:write_attribute, attribute_name, @table)
        end
      end

      define_singleton_method!(timestamp_attr_name) { @table[timestamp_attr_name]&.to_time }
      define_singleton_method!("#{timestamp_attr_name}=") do |x|
        @table[timestamp_attr_name] = x
        owner.send(:write_attribute, attribute_name, @table)
      end
    end
  end
end
