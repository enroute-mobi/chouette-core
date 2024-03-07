# frozen_string_literal: true

class CalendarPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('calendars.create')
  end

  def update?
    instance_permission('update')
  end

  def destroy?
    instance_permission('destroy')
  end

  def share?
    instance_permission('share')
  end

  def month?
    update?
  end

  private

  def instance_permission(permission)
    workbench_matches? && user.has_permission?("calendars.#{permission}")
  end
end
