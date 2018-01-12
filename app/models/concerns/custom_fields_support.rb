module CustomFieldsSupport
  extend ActiveSupport::Concern

  included do
    validate :custom_fields_values_are_valid

    def self.custom_fields
      CustomField.where(resource_type: self.name.split("::").last)
    end

    def custom_fields
      HashWithIndifferentAccess[*self.class.custom_fields.map do |v|
        [v.code, CustomField::Value.new(self, v, custom_field_value(v.code))]
      end.flatten]
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
