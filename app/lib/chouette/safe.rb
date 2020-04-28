module Chouette
  module Safe

    def self.capture(message, e)
      Rails.logger.error "[ERROR] #{message}: #{e} #{e.backtrace.join("\n")}"

      if ENV['SENTRY_DSN']
        Raven.capture_exception e
      end
    end

  end
end
