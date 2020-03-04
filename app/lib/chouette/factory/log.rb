module Chouette
  class Factory
    module Log
      def log(message)
        Rails.logger.debug "  [Factory] #{message}"
      end
    end
  end
end
