# frozen_string_literal: true

module Policy
  module Context
    # Base class for Policy::Context
    class Base
      include ActiveAttr::Attributes

      def self.from(provider)
        new.tap do |context|
          attribute_names.each do |attribute|
            # Extract value via current_attribute or attribute methods
            context.send "#{attribute}=", provider.send("current_#{attribute}")
          end
        end
      end
    end

    # Empty Context
    class Empty < Base
    end

    # Context that can respond to permission?
    module HasPermission
      def permission?
        raise NotImplementedError
      end

      private

      def permissions
        @permissions ||= Set.new(compute_permissions).freeze
      end

      def compute_permissions
        raise NotImplementedError
      end
    end

    # Context that have a workbench attribute
    module HasWorkbench
      extend ActiveSupport::Concern

      included do
        attribute :workbench
      end

      def workbench?(workbench)
        self.workbench == workbench
      end
    end

    # Context with associated User
    class User < Base
      include HasPermission

      attribute :user

      def user_organisation?(organisation)
        user.organisation == organisation
      end

      def permission?(permission)
        permissions.include?(permission)
      end

      private

      def compute_permissions
        user.permissions || []
      end
    end

    # Context with associated Workgroup
    class Workgroup < User
      attribute :workgroup

      def workgroup?(workgroup)
        self.workgroup == workgroup
      end
    end

    # Context with associated Workbench
    class Workbench < Workgroup
      include HasWorkbench

      private

      def compute_permissions
        super - (workbench.restrictions || [])
      end
    end

    # Context with only a Workbench (no User nor Workgroup)
    class OnlyWorkbench < Base
      include HasPermission
      include HasWorkbench

      def permission?(permission)
        !permissions.include?(permission)
      end

      private

      def compute_permissions
        workbench.restrictions || []
      end
    end

    # Context with associated Referential
    class Referential < Workbench
      attribute :referential

      delegate :referential_read_only?, to: :referential
    end
  end
end
