module RouteControl
  module InternalBaseInterface
    extend ActiveSupport::Concern

    included do
      include ComplianceControls::InternalControlInterface
    end

    class_methods do
      def collection_type(_)
        :routes
      end
    end
  end
end
