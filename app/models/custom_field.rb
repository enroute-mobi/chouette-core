class CustomField < ActiveRecord::Base

  extend Enumerize
  belongs_to :workgroup
  enumerize :field_type, in: %i{list}

  validates :name, uniqueness: {scope: [:resource_type, :workgroup_id]}
  validates :code, uniqueness: {scope: [:resource_type, :workgroup_id], case_sensitive: false}

  class Value
    def self.new custom_field, value
      field_type = custom_field.options["field_type"]
      klass_name = field_type && "CustomField::Value::#{field_type.classify}"
      klass = klass_name && const_defined?(klass_name) ? klass_name.constantize : CustomField::Value::Base
      klass.new custom_field, value
    end

    class Base
      def initialize custom_field, value
        @custom_field = custom_field
        @raw_value = value
      end

      %i(code name field_type options).each do |attr|
        define_method attr do
          @custom_field.send(attr)
        end
      end

      def value
        @raw_value
      end
    end

    class Integer < Base
      def value
        @raw_value.to_i
      end
    end

    class String < Base
      def value
        "#{@raw_value}"
      end
    end
  end
end
