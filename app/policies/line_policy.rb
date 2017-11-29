class LinePolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    !archived? && organisation_match? && user.has_permission?('lines.create')
  end

  def update?
    !archived? && organisation_match? && user.has_permission?('lines.update')
  end

  def destroy?
    !archived? && organisation_match? && user.has_permission?('lines.destroy')
  end

  def create_footnote?
    !archived? && organisation_match? && user.has_permission?('footnotes.create')
  end

  def edit_footnote?
    !archived? && organisation_match? && user.has_permission?('footnotes.update')
  end

  def destroy_footnote?
    !archived? && organisation_match? && user.has_permission?('footnotes.destroy')
  end

  def update_footnote?  ; edit_footnote? end
  def new_footnote?     ; create_footnote? end
end
