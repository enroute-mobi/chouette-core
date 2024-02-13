# frozen_string_literal: true

module Policy
  module Authorizer
    # Manage Policies inside a Controller
    class Controller
      # Defines Authorizer class used default in Controllers
      mattr_accessor :default_class

      mattr_reader :exceptions, default: {}

      # Specify (temporary) Authorizer for a given Controller class
      def self.for(controller_class, authorizer)
        exceptions[controller_class] = authorizer
      end

      # Returns Authorizer to be used by a Controller instance
      def self.from(controller)
        authorizer_class(controller).new(controller)
      end

      def initialize(controller)
        @controller = controller
      end

      attr_reader :controller

      # Creates Context used by Policy instances
      def context
        @context ||= context_class.from(controller)
      end

      def context_class
        controller.policy_context_class
      end

      # [Private] Returns Policy instance associated to the given resource
      def policy(resource)
        resource = resource.object if resource.is_a?(::AF83::Decorator::EnhancedDecorator) # meh...
        policy_class(resource).new resource, context: context
      end

      # [Private] Returns Policy class name associated to the given resource
      def policy_class_name(resource)
        "Policy::#{resource.class.name.demodulize}"
      end

      # [Private] Returns Policy class associated to the given resource
      def policy_class(resource)
        policy_class_name(resource).constantize
      end

      # [Private] Returns Authorizer class assocaited to the given Controller instance
      def self.authorizer_class(controller)
        exceptions[controller.class] || default_class || self
      end
    end

    # Manage Policies (in a Controller) by using legacy Pundit policies
    class Legacy
      def initialize(controller)
        @controller = controller
      end

      attr_reader :controller

      def pundit_user_context
        @pundit_user_context ||=
          UserContext.new(current_user,
                          referential: current_referential,
                          workbench: current_workbench,
                          workgroup: current_workgroup)
      end

      def current(name)
        controller.send "current_#{name}"
      rescue NoMethodError, RSpec::Mocks::MockExpectationError
        nil
      end

      def current_user
        current :user
      end

      def current_referential
        current :referential
      end

      def current_workgroup
        current :workgroup
      end

      def current_workbench
        current :workbench
      end

      def policy(resource)
        policy_class.new(pundit_user_context, resource)
      end

      def policy_class
        Policy::Legacy
      end
    end

    # Use Policy::PermitAll
    class PermitAll
      def initialize(*arguments); end

      def policy(resource)
        Policy::PermitAll.new resource
      end
    end
  end
end
