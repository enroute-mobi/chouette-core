# frozen_string_literal: true

class DocumentMembershipPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('document_memberships.create') && parent_has_permission? && provider_matches?
  end

  def destroy?
    user.has_permission?('document_memberships.destroy') && parent_has_permission? && provider_matches?
  end

  private

  def parent_has_permission?
    user.has_permission?("#{documentable_policy_name}.update")
  end

  def provider_matches?
    @current_workbench && record.documentable.same_documentable_workbench?(@current_workbench)
  end

  def documentable_policy_name
    record.documentable.class.name.demodulize.underscore.pluralize
  end
end
