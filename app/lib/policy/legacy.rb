# frozen_string_literal: true

module Policy
  # Use Pundit Policy to authorize actions on given resource
  class Legacy < Base
    def initialize(pundit_context, resource)
      super resource
      @pundit_context = pundit_context
    end

    attr_reader :pundit_context

    undef edit?
    undef update?
    undef destroy?

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
      resource_class ||= if resource.is_a?(ActiveRecord::Relation)
                           resource.klass
                         else
                           resource.class
                         end

      Pundit::PolicyFinder.new(resource_class).policy
    end

    protected

    # Returns true if given resource class can be create according Pundit policy
    def _create?(resource_class)
      pundit_create_policy(resource_class).create?
    end
    alias _new? _create?

    # Returns true if given action is permitted by associated Pundit policy
    def _can?(action, *arguments)
      if arguments.length == 1 && arguments[0].is_a?(Class) && arguments[0] < ActiveRecord::Base
        pundit_create_policy(arguments[0]).send("#{action}?")
      else
        pundit_policy.send "#{action}?", *arguments
      end
    end

    private

    def apply_strategies(_action, *_args)
      true
    end
  end
end
