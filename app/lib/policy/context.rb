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
            value = provider.try("current_#{attribute}") || provider.try(attribute)
            context.send "#{attribute}=", value
          end
        end
      end
    end

    # Empty Context
    class Empty < Base
    end

    # Context with associated User
    class User < Base
      attribute :user
    end

    # Context with associated Workgroup
    class Workgroup < User
      attribute :workgroup
    end

    # Context with associated Workbench
    class Workbench < Workgroup
      attribute :workbench
    end

    # Context with associated Referential
    class Referential < Workbench
      attribute :referential
    end
  end
end
