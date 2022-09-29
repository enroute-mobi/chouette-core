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
      return send(option_method)
    end

    # By default, options don't require permission
    true
  end

  def has_permission?(permission)
    return false unless user || workbench

    return false if user && !user.has_permission?(permission)

    return false if workbench && workbench.has_restriction?(permission)

    # Example for the future - Ignore me
    # Include here ApiKey permissions in the future
    # if api_key && !api_key.has_permission?(permission)
    #   return false
    # end

    true
  end

  def option_flag_urgent?
    has_permission? 'referentials.flag_urgent'
  end

  def option_update_workgroup_providers?
    has_permission? 'imports.update_workgroup_providers'
  end

  def option_store_xml?
    has_permission? 'imports.import_netex_store_xml'
  end

end
