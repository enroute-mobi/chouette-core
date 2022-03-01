class CustomFieldGroup < ApplicationModel

  extend Enumerize
  belongs_to :custom_field
  acts_as_list scope: 'custom_field_id #{custom_field_id ? "= #{custom_field_id}" : "IS NULL"} AND custom_field_group_id #{custom_field_group_id ? "= #{custom_field_group_id}" : "IS NULL"}'
end
