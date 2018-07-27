class ReferentialPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def browse?
    record.active? || record.archived?
  end

  def create?
    user.has_permission?('referentials.create')
  end

  def destroy?
    !record.pending? && !record.in_referential_suite? && organisation_match? && user.has_permission?('referentials.destroy')
  end

  def update?
    !referential_read_only? && organisation_match? && user.has_permission?('referentials.update')
  end

  def clone?
    record.ready? && !record.in_referential_suite? && create?
  end

  def validate?
    record.active? && organisation_match?
  end

  def archive?
    !referential_read_only? && record.archived_at.nil? && organisation_match? && user.has_permission?('referentials.update')
  end

  def unarchive?
    record.ready? && record.archived? && !record.merged? && organisation_match? && user.has_permission?('referentials.update')
  end

  def common_lines?
    # TODO: Replace with correct BL ASA available, c.f. https://projects.af83.io/issues/2692
    true
  end

  def referential_read_only?
    record.referential_read_only?
  end
end
