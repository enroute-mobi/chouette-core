# frozen_string_literal: true

module Policy
  class Referential < Base
    # NOTE: we cannot apply strategy Referential to :update
    # since then we won't be able to apply :update strategies for :unarchive
    # we also cannot apply strategy Referential for archive
    # since this policy is sometimes checked in contexts without referential
    authorize_by Strategy::Referential, only: %i[create]
    authorize_by Strategy::Workbench, only: %i[update destroy validate flag_urgent]
    authorize_by Strategy::Permission, only: %i[create update destroy flag_urgent]

    def browse?
      around_can(:browse) { resource.active? || resource.archived? }
    end

    def clone?
      around_can(:clone) do
        resource.ready? &&
          !resource.in_referential_suite? &&
          ::Policy::Workbench.new(resource.workbench, context: context).create?(::Referential)
      end
    end

    def validate?
      around_can(:validate) { resource.active? }
    end

    def archive?
      around_can(:archive) do
        check_context_class(:update) && apply_strategies_for(:update, :update) &&
          !resource.referential_read_only? && resource.archived_at.nil?
      end
    end

    def unarchive?
      around_can(:unarchive) do
        check_context_class(:update) && apply_strategies_for(:update, :update) &&
          resource.ready? && resource.archived? && !resource.merged?
      end
    end

    def flag_urgent?
      around_can(:flag_urgent) { true }
    end

    protected

    def _create?(resource_class)
      [
        ::Chouette::Route,
        ::Chouette::RoutingConstraintZone,
        ::Chouette::TimeTable
      ].include?(resource_class)
    end

    def _update?
      !resource.referential_read_only?
    end

    def _destroy?
      !resource.pending? && !resource.in_referential_suite? && !resource.merged?
    end
  end
end
