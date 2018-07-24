class FootnotePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def edit_all?
    !referential_read_only? && organisation_match? && user.has_permission?('footnotes.update')
  end

  def destroy?
    !referential_read_only? && organisation_match? && user.has_permission?('footnotes.destroy')
  end

  def update_all?  ; edit_all? end

end
