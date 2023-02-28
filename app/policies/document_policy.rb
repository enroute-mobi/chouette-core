class DocumentPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('documents.create')
  end

  def update?
    user.has_permission?('documents.update') && document_provider_matches?
  end

  def destroy?
    user.has_permission?('documents.destroy') && document_provider_matches?
  end

  def document_provider_matches?
    current_workbench.document_providers.exists?(id: record.document_provider)
  end

end
