# frozen_string_literal: true

require 'logger/log_device'

module Chouette
  module SemanticLogger
    module Appender
      # Changes default semantic logger file appender to replace its @file with a Logger::LogDevice.
      # The only public methods using @file are #log, #reopen and #flush.
      # * #log: @file is only used to call its #write method.
      #         #write has the same behavior in Logger::LogDevice but implements the rotation mechanism.
      # * #reopen: simply delegate to Logger::LogDevice that does the same thing without the rotation mechanism.
      # * #flush: simply delegate to Logger::LogDevice file object, dev
      class RotatingFile < ::SemanticLogger::Appender::File
        # disables the header added to each log file:
        #   # Logfile created on 2024-04-10 16:49:34 +0200 by logger.rb/v1.4.2
        class LogDevice < ::Logger::LogDevice
          def add_log_header(_file); end
        end

        def initialize(file_name, reopen_max: 0, reopen_size: 0, encoding: ::Encoding::BINARY, **args, &block) # rubocop:disable Metrics/MethodLength
          super(
            file_name,
            append: true,
            reopen_period: nil,
            reopen_count: 0,
            reopen_size: 0,
            encoding: encoding,
            exclusive_lock: false,
            **args,
            &block
          )

          @file = LogDevice.new(
            file_name,
            shift_age: reopen_max,
            shift_size: reopen_size,
            binmode: encoding == Encoding::BINARY
          )
        end
        attr_reader :file

        delegate :reopen, to: :file

        def flush
          file.dev.flush
        end
      end
    end
  end
end
