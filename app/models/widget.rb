# frozen_string_literal: true

class Widget < ActiveRecord::Base
  belongs_to :dashboard

  validates :name, :widget_type, :data_source, presence: true
  validates :widget_type, inclusion: { in: Dashboard::WIDGET_TYPES }
  validates :data_source, inclusion: { in: Dashboard::DATA_SOURCES }

  scope :ordered, -> { order(position: :asc) }

  # Use jsonb column type in the database for better querying
  attribute :options, :jsonb, default: -> { {}}

  def self.types
    Dashboard::WIDGET_TYPES
  end

  def self.data_sources
    Dashboard::DATA_SOURCES
  end
end