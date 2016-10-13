class CompanyPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    false
  end
  def update?  ; create? end
  def new?     ; create? end
  def edit?    ; create? end
  def destroy? ; create? end
end
