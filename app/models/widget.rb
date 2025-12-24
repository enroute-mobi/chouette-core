# frozen_string_literal: true

class Widget < ActiveRecord::Base
  extend Enumerize
  belongs_to :dashboard, touch: true

  validates :name, :widget_type, presence: true
  enumerize :widget_type, in: %w[image chart counter list numbers static_text table]

  attribute :options, :jsonb, default: -> { {}}

  def self.types
    widget_type.values
  end
end