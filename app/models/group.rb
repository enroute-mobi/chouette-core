# frozen_string_literal: true

class Group < ApplicationModel
  self.abstract_class = true
  include CodeSupport
  validates :name, presence: true
  validates :short_name, format: { with: /\A[a-zA-Z0-9_-]+\z/ }, allow_blank: true

  class Member < ApplicationModel
    self.abstract_class = true
    belongs_to :group # CHOUETTE-3247 code analysis
  end
end
