# frozen_string_literal: true

module Fare
  # Regroups all Fare models associated to a Workgroup
  class Referential < ApplicationModel
    self.table_name = :fare_referentials

    belongs_to :workgroup

    has_many :fare_providers, class_name: 'Fare::Provider', foreign_key: 'fare_referential_id', dependent: :destroy
    has_many :fare_zones, through: :fare_providers
    has_many :fare_products, through: :fare_providers
    has_many :fare_validities, through: :fare_providers
  end
end
