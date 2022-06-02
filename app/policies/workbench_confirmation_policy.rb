class WorkbenchConfirmationPolicy < ApplicationPolicy

  def create?
    user.has_permission?('workbenches.confirm')
  end

end
