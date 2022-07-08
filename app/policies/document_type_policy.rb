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
    # A DocumentType should not be destroyed if they are linked to a document (mandatory attribute)
    user.has_permission?('document_types.destroy') && record.documents.empty?
  end

  def update?
    user.has_permission?('document_types.update')
  end
end
