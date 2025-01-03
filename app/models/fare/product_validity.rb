# frozen_string_literal: true

module Fare
  # Link Validity and Product
  class ProductValidity < ApplicationModel
    self.table_name = 'fare_products_validities'

    belongs_to :product, class_name: 'Fare::Product', foreign_key: 'fare_product_id', inverse_of: :product_validities # TODO: CHOUETTE-3247 optional: true?
    belongs_to :validity, class_name: 'Fare::Validity', foreign_key: 'fare_validity_id', inverse_of: :product_validities # TODO: CHOUETTE-3247 optional: true?
  end
end
