class CustomField < ActiveRecord::Base

  extend Enumerize
  belongs_to :workgroup
  enumerize :field_type, in: %i{list}

  validates :name, uniqueness: {scope: [:resource_type, :workgroup_id]}
  validates :code, uniqueness: {scope: [:resource_type, :workgroup_id], case_sensitive: false}

  class Collection < HashWithIndifferentAccess
    def initialize object
      vals = object.class.custom_fields.map do |v|
        [v.code, CustomField::Value.new(object, v, object.custom_field_value(v.code))]
      end
      super Hash[*vals.flatten]
    end

    def to_hash
      HashWithIndifferentAccess[*self.map{|k, v| [k, v.to_hash]}.flatten(1)]
    end
  end

  class Value
    def self.new owner, custom_field, value
      field_type = custom_field.options["field_type"]
      klass_name = field_type && "CustomField::Value::#{field_type.classify}"
      klass = klass_name && const_defined?(klass_name) ? klass_name.constantize : CustomField::Value::Base
      klass.new owner, custom_field, value
    end

    class Base
      def initialize owner, custom_field, value
        @custom_field = custom_field
        @raw_value = value
        @owner = owner
        @errors = []
        @validated = false
        @valid = false
      end

      delegate :code, :name, :field_type, :options, to: :@custom_field

      def validate
        @valid = true
      end

      def valid?
        validate unless @validated
        @valid
      end

      def value
        @raw_value
      end

      def errors_key
        "custom_fields.#{code}"
      end

      def to_hash
        HashWithIndifferentAccess[*%w(code name field_type options value).map{|k| [k, send(k)]}.flatten(1)]
      end
    end

    class Integer < Base
      def value
        @raw_value.to_i
      end

      def validate
        @valid = true
        unless @raw_value =~ /\A\d*\Z/
          @owner.errors.add errors_key, "'#{@raw_value}' is not a valid integer"
          @valid = false
        end
      end
    end

    class String < Base
      def value
        "#{@raw_value}"
      end
    end
  end
end
