module RouteControl
  module InternalBaseInterface
    extend ActiveSupport::Concern

    included do
      include ComplianceControls::InternalControlInterface
      
      def self.collection_type(_)
        :routes
      end
    end
  end
end
