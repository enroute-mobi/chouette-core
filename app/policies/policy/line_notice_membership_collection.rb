# frozen_string_literal: true

module Policy
  class LineNoticeMembershipCollection < Base
    protected

    def _update?
      ::Policy::Line.new(resource.proxy_association.owner, context: context).update?
    end
  end
end
