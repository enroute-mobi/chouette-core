# frozen_string_literal: true

class Group < ApplicationModel
  self.abstract_class = true
  include CodeSupport
  validates :name, presence: true

  class Member < ApplicationModel
    self.abstract_class = true
    belongs_to :group
  end
end
