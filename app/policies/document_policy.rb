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
    user.has_permission?('documents.update')
  end

  def destroy?
    user.has_permission?('documents.destroy')
  end
end
