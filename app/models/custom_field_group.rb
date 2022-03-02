class CustomFieldGroup < ApplicationModel

  extend Enumerize
  belongs_to :workgroup

  has_many :custom_fields, -> { order(position: :asc) }, class_name: "CustomField", dependent: :delete_all, foreign_key: "custom_field_group_id", inverse_of: :custom_field_group
end
