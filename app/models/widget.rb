# frozen_string_literal: true

class Widget < ActiveRecord::Base
  belongs_to :dashboard, touch: true

  validates :name, :widget_type, presence: true
  validates :widget_type, inclusion: { in: Dashboard::WIDGET_TYPES }

  attribute :options, :jsonb, default: -> { {}}

  def self.types
    Dashboard::WIDGET_TYPES
  end
end