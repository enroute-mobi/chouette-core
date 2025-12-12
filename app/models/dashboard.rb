# frozen_string_literal: true

class Dashboard < ApplicationModel
  belongs_to :workbench
  has_many :widgets, dependent: :destroy

  accepts_nested_attributes_for :widgets, allow_destroy: true

  validates :name, presence: true
  validates :workbench, presence: true

  WIDGET_TYPES = %w[default chart counter list numbers static_text table].freeze
  DATA_SOURCES = %w[referentials lines stop_areas].freeze
end