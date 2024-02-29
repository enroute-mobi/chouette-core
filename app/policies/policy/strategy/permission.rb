# frozen_string_literal: true

module Policy
  module Strategy
    class Permission < Strategy::Base
      class << self
        def context_class
          ::Policy::Context::User
        end
      end

      def apply(action, *args)
        context.permission?(required_permission(action, *args))
      end

      private

      def required_permission(action, *args)
        if action == :create
          "#{permission_namespace_from_class(args[0])}.#{action}"
        else
          "#{permission_namespace}.#{action}"
        end
      end

      def permission_namespace_from_class(klass)
        to_permission_namespace(klass.model_name.to_s)
      end

      def permission_namespace
        @permission_namespace ||= to_permission_namespace(policy.class.name.sub(PERMISSION_NAMESPACE_REGEXP, ''))
      end
      PERMISSION_NAMESPACE_REGEXP = /\APolicy::/.freeze

      def to_permission_namespace(class_name)
        class_name.underscore.tr('/', '_').pluralize
      end
    end
  end
end
