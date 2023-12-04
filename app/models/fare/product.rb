# frozen_string_literal: true

module Fare
  # Regroups several Fare models into a Workbench
  class Product < ApplicationModel
    self.table_name = :fare_products

    belongs_to :fare_provider, class_name: 'Fare::Provider' # CHOUETTE-3247 optional: false
    has_one :fare_referential, through: :fare_provider
    has_one :workbench, through: :fare_provider

    include CodeSupport

    belongs_to :company, class_name: 'Chouette::Company', optional: true # CHOUETTE-3247

    has_many :product_validities, class_name: 'Fare::ProductValidity',
                                  foreign_key: 'fare_product_id', dependent: :delete_all
    has_many :validites, through: :product_validities

    validates :name, presence: true
  end
end
