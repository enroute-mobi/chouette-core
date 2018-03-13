module CustomFieldsSupport
  extend ActiveSupport::Concern

  included do
    validate :custom_fields_values_are_valid
    after_initialize :initialize_custom_fields

    def self.custom_fields
      CustomField.where(resource_type: self.name.split("::").last)
    end

    def custom_fields
      CustomField::Collection.new self
    end

    def custom_field_values= vals
      out = {}
      custom_fields.each do |code, field|
        out[code] = field.preprocess_value_for_assignment(vals[code])
      end
      self.write_attribute :custom_field_values, out
    end

    def initialize_custom_fields
      self.custom_field_values ||= {}
      custom_fields.values.each &:initialize_custom_field
    end

    def custom_field_value key
      (custom_field_values || {})[key.to_s]
    end

    private
    def custom_fields_values_are_valid
      custom_fields.values.all?{|cf| cf.valid?}
    end
  end
end
