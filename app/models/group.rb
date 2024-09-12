class Group < ApplicationModel
  self.abstract_class = true
  include CodeSupport
  validates :name, presence: true

  before_destroy :can_destroy?, prepend: true

  class Member < ApplicationModel
    self.abstract_class = true
    belongs_to :group
  end

  def used?
    members.exists?
  end

  private

  def can_destroy?
    if used?
      self.errors.add(:base, "Can't be destroy because it has at least one member")
      throw :abort
    end
  end
end