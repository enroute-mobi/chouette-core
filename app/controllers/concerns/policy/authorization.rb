# frozen_string_literal: true

module Policy
  module Authorization
    extend ActiveSupport::Concern

    included do
      delegate :policy, to: :authorizer

      helper_method :policy
    end

    def policy_context_class
      ::Policy::Context::Empty
    end

    private

    def authorize(record, query = nil, *args)
      authorize_policy(policy(record), query, *args)
    end

    def authorize_policy(policy, query, *args)
      query ||= :"#{action_name}?"
      policy.public_send(query, *args) || (raise NotAuthorizedError)
    end

    def authorizer
      @authorizer ||= Authorizer::Controller.from(self)
    end
  end
end
