# frozen_string_literal: true

module Fare
  # Regroups several Fare models into a Workbench
  class Product < ApplicationModel
    self.table_name = :fare_products

    belongs_to :fare_provider, class_name: 'Fare::Provider', optional: false
    has_one :fare_referential, through: :fare_provider
    has_one :workbench, through: :fare_provider

    include CodeSupport

    belongs_to :company, class_name: 'Chouette::Company', optional: true
    has_and_belongs_to_many :validities, class_name: 'Fare::Validity', 
      foreign_key: 'fare_product_id', association_foreign_key: 'fare_validity_id', join_table: :fare_products_validities

    validates :name, presence: true
  end
end
