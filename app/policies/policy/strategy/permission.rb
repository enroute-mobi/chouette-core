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
          "#{args[0].name.demodulize.underscore.pluralize}.#{action}"
        else
          "#{permission_namespace}.#{action}"
        end
      end

      def permission_namespace
        @permission_namespace ||= policy.class.name.demodulize.underscore.pluralize
      end
    end
  end
end
