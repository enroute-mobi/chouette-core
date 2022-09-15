module Chouette
  module Safe
    def self.capture(message, e)
      Error.new(e, message: message).capture
    end

    class Error
      def initialize(error, message: nil)
        @error = error
        @message = message
      end
      attr_reader :error, :message

      def capture
        log_capture
        sentry_capture

        uuid
      end

      def log_capture
        Rails.logger.error log_message
      end

      def sentry_capture
        Sentry.capture_exception error, tags: {uuid: uuid} if ENV['SENTRY_DSN']
      end

      def log_message
        "[ERROR] #{message} (#{uuid}): #{error.class.name} #{error.message} #{error.backtrace.join("\n")}"
      end

      def uuid
        @uuid ||= SecureRandom.uuid
      end
    end

  end
end
