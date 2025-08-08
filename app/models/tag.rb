# frozen_string_literal: true

class Tag < ApplicationModel
  belongs_to :workbench
  has_many :taggings, dependent: :destroy
  has_many :imports, through: :taggings, source: :taggable, source_type: 'Import::Base'

  validates :name, presence: true, uniqueness: { scope: :workbench_id }

  include ColorSupport

  open_color_attribute
end
