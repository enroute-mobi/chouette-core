module Chouette
  module Safe

    def self.execute(error_msg, &block)
      _execute(&block) # => need to do this to be able to test that the error is captured (TODO improve this)
    rescue => e
      capture(error_msg, e)  
    end

    def self.capture(message, e)
      Rails.logger.error "[ERROR] #{message}: #{e.class.name} #{e.message} #{e.backtrace.join("\n")}"

      if ENV['SENTRY_DSN']
        Raven.capture_exception e
      end
    end

    def self._execute(&block)
      block.call
    end
  end
end
