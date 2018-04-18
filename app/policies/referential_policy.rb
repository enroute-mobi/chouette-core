class ReferentialPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def browse?
    record.ready? || record.archived?
  end

  def create?
    user.has_permission?('referentials.create')
  end

  def destroy?
    !referential_read_only? && organisation_match? && user.has_permission?('referentials.destroy')
  end

  def update?
    !referential_read_only? && organisation_match? && user.has_permission?('referentials.update')
  end

  def clone?
    !record.in_referential_suite? && create?
  end

  def validate?
    !referential_read_only? && create? && organisation_match?
  end

  def archive?
    !referential_read_only? && record.archived_at.nil? && organisation_match? && user.has_permission?('referentials.update')
  end

  def unarchive?
    record.archived? && !record.merged? && organisation_match? && user.has_permission?('referentials.update')
  end

  def common_lines?
    # TODO: Replace with correct BL ASA available, c.f. https://projects.af83.io/issues/2692
    true
  end

end
