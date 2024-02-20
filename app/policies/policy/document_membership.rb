# frozen_string_literal: true

module Policy
  class DocumentMembership < Base
    authorize_by Strategy::Permission

    protected

    def _destroy?
      documentable_policy.update?
    end

    private

    def documentable_policy
      @documentable_policy ||= documentable_policy_class.new(resource.documentable, context: context)
    end

    def documentable_policy_class
      "Policy::#{resource.documentable.class.name.demodulize}".constantize
    end
  end
end
