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

      # [Private] Returns Policy class name associated to the given resource class
      def self.policy_class_name(resource_or_resource_class)
        result = "Policy::#{resource_or_resource_class.model_name}"
        result = "#{result}Collection" if resource_or_resource_class.is_a?(ActiveRecord::Relation)
        result
      end

      # Returns Policy class associated to the given resource class
      def self.policy_class(resource_or_resource_class)
        policy_class_name(resource_or_resource_class).safe_constantize
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
        return ::Policy::DenyAll.instance if resource.nil?

        resource = resource.object if resource.is_a?(::Af83::Decorator::EnhancedDecorator) # meh...
        self.class.policy_class(resource).new resource, context: context
      end

      # [Private] Returns Authorizer class assocaited to the given Controller instance
      def self.authorizer_class(controller)
        exceptions[controller.class] || default_class || self
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
