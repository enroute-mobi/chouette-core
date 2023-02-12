# frozen_string_literal: true

module Fare
  # A Zone (including Stop Areas) used to define Fare validities
  class Zone < ApplicationModel
    self.table_name = :fare_zones

    belongs_to :fare_provider, class_name: 'Fare::Provider'
    has_one :fare_referential, through: :fare_provider
    has_one :workbench, through: :fare_provider

    has_many :codes, as: :resource, dependent: :delete_all

    validates :name, presence: true

    has_and_belongs_to_many :stop_areas, class_name: 'Chouette::StopArea', join_table: :fare_stop_areas_zones
  end
end
