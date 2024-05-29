# frozen_string_literal: true

module Policy
  class LineNoticeMembership < Base
    protected

    def _destroy?
      ::Policy::Line.new(resource.line, context: context).update?
    end
  end
end
