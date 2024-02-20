# frozen_string_literal: true

module Policy
  class User < Base
    class NotSelfStrategy < Strategy::Base
      class << self
        def context_class
          ::Policy::Context::User
        end
      end

      def apply(_action, *_args)
        resource != context.user
      end
    end

    class << self
      def context_class(action)
        if action == :workbench_confirm
          ::Policy::Context::User
        else
          super
        end
      end
    end

    authorize_by NotSelfStrategy, only: %i[update destroy]
    authorize_by Strategy::Permission, only: %i[create update destroy]

    def block?
      around_can(:block) { update? && !resource.blocked? }
    end

    def unblock?
      around_can(:unblock) { update? && resource.blocked? }
    end

    def reinvite?
      around_can(:reinvite) { create?(::User) && resource.state == :invited }
    end

    alias invite? create?
    alias new_invitation? invite?

    def reset_password?
      around_can(:reset_password) { update? && resource.state == :confirmed }
    end

    def workbench_confirm?(_resource_class)
      around_can(:workbench_confirm) { context.permission?('workbenches.confirm') }
    end

    protected

    def _create?(resource_class)
      [
        ::User,
        ::Workgroup
      ].include?(resource_class)
    end

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
