class ImportPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(workbench_id: user.organisation.workbench_ids)
    end
  end

  def show?
    super || record.workbench.workgroup.owner == user.organisation
  end

  def create?
    user.has_permission?('imports.create')
  end

  def update?
    user.has_permission?('imports.update')
  end

  def option?(option_name)
    option_method = "option_#{option_name}?"
    if respond_to? option_method
      return option_flag_urgent?
    end

    # By default, options don't require permission
    true
  end

  def option_flag_urgent?
    user.has_permission?('referentials.flag_urgent')
  end

end
