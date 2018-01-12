module CustomFieldsSupport
  extend ActiveSupport::Concern

  included do
    def self.custom_fields
      CustomField.where(resource_type: self.name.split("::").last)
    end

    def custom_fields
      HashWithIndifferentAccess[*self.class.custom_fields.map do |v|
        [v.code, CustomField::Value.new(v, custom_field_value(v.code))]
      end.flatten]
    end

    def custom_field_value key
      (custom_field_values || {})[key.to_s]
    end
  end
end
