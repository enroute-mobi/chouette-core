class FareProviderPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('fare_providers.create')
  end

  def update?
    user.has_permission?('fare_providers.update')
  end

  def destroy?
    user.has_permission?('fare_providers.destroy')
  end

end
