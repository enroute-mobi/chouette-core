# frozen_string_literal: true

module Policy
  module Strategy
    class ShapeProvider < Strategy::Provider
      protected

      def provider
        resource.shape_provider
      end
    end
  end
end
