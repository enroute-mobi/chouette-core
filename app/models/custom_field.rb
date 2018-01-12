class CustomField < ActiveRecord::Base

  extend Enumerize
  belongs_to :workgroup
  enumerize :field_type, in: %i{list}

  validates :name, uniqueness: {scope: [:resource_type, :workgroup_id]}
  validates :code, uniqueness: {scope: [:resource_type, :workgroup_id], case_sensitive: false}

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
      end

      %i(code name field_type options).each do |attr|
        define_method attr do
          @custom_field.send(attr)
        end
      end

      def valid?
        true
      end

      def value
        @raw_value
      end

      def errors_key
        "custom_fields.#{code}"
      end
    end

    class Integer < Base
      def value
        @raw_value.to_i
      end

      def valid?
        unless ActiveRecord::Base::NumericalityValidator.new(attributes: 42).send(:parse_raw_value_as_an_integer, @raw_value).present?
          @owner.errors.add errors_key, "'#{@raw_value}' is not a valid integer"
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
