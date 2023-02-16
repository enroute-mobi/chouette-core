# frozen_string_literal: true

module Fare
  # Regroups several Fare models into a Workbench
  class Provider < ApplicationModel
    self.table_name = :fare_providers

    belongs_to :workbench, optional: false
    belongs_to :fare_referential, class_name: 'Fare::Referential', optional: false

    validates :short_name, presence: true

    with_options(dependent: :destroy, foreign_key: :fare_provider_id) do
      has_many :fare_zones, class_name: 'Fare::Zone'
      has_many :fare_products, class_name: 'Fare::Product'
      has_many :fare_validities, class_name: 'Fare::Validity'
    end
  end
end
