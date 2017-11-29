class FootnotePolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    !archived? && organisation_match? && user.has_permission?('footnotes.create')
  end

  def update?
    !archived? && organisation_match? && user.has_permission?('footnotes.update')
  end

  def destroy?
    !archived? && organisation_match? && user.has_permission?('footnotes.destroy')
  end
end
