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
    user.has_permission?('documents.update') && workbench_match?
  end

  def destroy?
    user.has_permission?('documents.destroy') && workbench_match?
  end

  def workbench_match?
    current_workbench.document_providers.exists?(id: record.document_provider)
  end

end
