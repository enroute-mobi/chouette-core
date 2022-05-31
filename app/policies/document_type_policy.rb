class DocumentTypePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('document_types.create')
  end

  def destroy?
    user.has_permission?('document_types.destroy')
  end

  def update?
    user.has_permission?('document_types.update')
  end
end
