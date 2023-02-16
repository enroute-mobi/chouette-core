# frozen_string_literal: true

module Fare
  # Link Validity and Product
  class ProductValidity < ApplicationModel
    self.table_name = 'fare_products_validities'

    belongs_to :product, class_name: 'Fare::Product', foreign_key: 'fare_product_id'
    belongs_to :validity, class_name: 'Fare::Validity', foreign_key: 'fare_validity_id'
  end
end
