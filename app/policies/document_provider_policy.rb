class DocumentProviderPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('document_providers.create')
  end

  def destroy?
    user.has_permission?('document_providers.destroy')
  end

  def update?
    user.has_permission?('document_providers.update')
  end

end