# frozen_string_literal: true

module Policy
  module Strategy
    class DocumentProvider < Strategy::Provider
      protected

      def provider
        resource.document_provider
      end
    end
  end
end
