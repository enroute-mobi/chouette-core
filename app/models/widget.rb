# frozen_string_literal: true

class Widget < ActiveRecord::Base
  extend Enumerize
  belongs_to :dashboard, touch: true

  validates :name, :widget_type, presence: true
  enumerize :widget_type, in: %w[image chart counter list numbers static_text table]
  
  # Grid position attributes with defaults for 3-column grid
  attribute :x, :integer, default: 0
  attribute :y, :integer, default: 0
  attribute :width, :integer, default: 1
  attribute :height, :integer, default: 2

  def self.types
    widget_type.values
  end
end
