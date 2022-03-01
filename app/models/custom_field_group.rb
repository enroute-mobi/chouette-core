class CustomFieldGroup < ApplicationModel

  extend Enumerize
  has_many :custom_fields
end
