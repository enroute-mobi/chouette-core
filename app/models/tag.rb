# frozen_string_literal: true

class Tag < ApplicationModel
  belongs_to :workbench
  has_many :taggings, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :workbench_id }

  include ColorSupport

  open_color_attribute
end
