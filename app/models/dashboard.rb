# frozen_string_literal: true

class Dashboard < ApplicationModel
  belongs_to :workbench
  has_many :widgets, dependent: :destroy
  accepts_nested_attributes_for :widgets, allow_destroy: true

  validates :name, presence: true
end