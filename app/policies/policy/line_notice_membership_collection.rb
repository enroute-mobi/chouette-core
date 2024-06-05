# frozen_string_literal: true

module Policy
  class LineNoticeMembershipCollection < Base
    authorize_by Strategy::Permission
    permission_exception :update, 'line_notice_memberships.destroy'

    protected

    def _update?
      line_policy = ::Policy::Line.new(resource.proxy_association.owner, context: context)
      line_policy.update? && line_policy.create?(::Chouette::LineNoticeMembership)
    end
  end
end
