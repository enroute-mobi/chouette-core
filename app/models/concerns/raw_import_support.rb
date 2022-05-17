module RawImportSupport
  extend ActiveSupport::Concern

  included do
    has_one :raw_import, as: :model, dependent: :delete
    accepts_nested_attributes_for :raw_import
  end
end