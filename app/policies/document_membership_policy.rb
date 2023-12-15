class DocumentMembershipPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('document_memberships.create') && user.has_permission?('lines.update')
  end

  def destroy?
    user.has_permission?('document_memberships.destroy') && user.has_permission?('lines.update') && provider_matches?
  end

  def provider_matches?
    if record.documentable.is_a?(Chouette::Line)
      @current_workbench && @current_workbench.id == record.documentable.line_provider.workbench_id
    elsif record.documentable.is_a?(Chouette::StopArea)
      @current_workbench && @current_workbench.id == record.documentable.stop_area_provider.workbench_id
    else
      false
    end
  end
end
