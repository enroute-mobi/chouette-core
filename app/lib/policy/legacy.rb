# frozen_string_literal: true

module Policy
  # Use Pundit Policy to authorize actions on given resource
  class Legacy < Base
    def initialize(pundit_context, resource)
      super resource
      @pundit_context = pundit_context
    end

    # Returns true if given resource class can be create according Pundit policy
    def create?(resource_class)
      pundit_create_policy(resource_class).create?
    end

    # Returns true if given action is permitted by associated Pundit policy
    def can?(action, *arguments)
      pundit_policy.send "#{action}?", *arguments
    end

    attr_reader :pundit_context

    # [Private] Returns Pundit Policy for resource
    def pundit_policy
      pundit_policy_class.new(pundit_context, resource)
    end

    # [Private] Returns Pundit 'Create' Policy for given resource class
    def pundit_create_policy(resource_class)
      pundit_policy_class(resource_class).new(pundit_context, resource_class)
    end

    # [Private] Find Pundit policy class either for resource or given resource class
    def pundit_policy_class(resource_class = nil)
      resource_class ||= resource.class
      Pundit::PolicyFinder.new(resource_class).policy
    end
  end
end
