# frozen_string_literal: true

module Policy
  module Strategy
    class Permission < Strategy::Base
      class << self
        def context_class
          ::Policy::Context::User
        end

        def to_permission_namespace(class_name)
          class_name.underscore.tr('/', '_').pluralize
        end
      end

      module PolicyConcern
        extend ActiveSupport::Concern

        class_methods do
          def permission_namespace
            @permission_namespace ||= ::Policy::Strategy::Permission.to_permission_namespace(name['Policy::'.length..])
          end

          def permission_exceptions
            @permission_exceptions ||= {}
          end

          def permission_exception(action, permission)
            permission_exceptions[action] = permission
          end
        end
      end

      def apply(action, *args)
        context.permission?(required_permission(action, *args))
      end

      private

      def required_permission(action, *args)
        exception = policy.class.permission_exceptions[action]
        if exception
          exception
        elsif action == :create
          "#{permission_namespace_from_class(args[0])}.#{action}"
        else
          "#{policy.class.permission_namespace}.#{action}"
        end
      end

      def permission_namespace_from_class(klass)
        policy_class = ::Policy::Authorizer::Controller.policy_class(klass)
        if policy_class
          policy_class.permission_namespace
        else
          self.class.to_permission_namespace(klass.name)
        end
      end
    end
  end
end
