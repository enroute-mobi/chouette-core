# frozen_string_literal: true

class Group < ApplicationModel
  self.abstract_class = true
  include CodeSupport
  validates :name, presence: true
  validates :short_name, presence: true, format: { with: /\A[a-zA-Z0-9_-]+\z/ }

  class Member < ApplicationModel
    self.abstract_class = true
    belongs_to :group
  end
end
