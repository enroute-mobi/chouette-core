# frozen_string_literal: true

# mostly copied from rails_semantic_logger/engine
config = Rails.configuration
if config.logger_reopen_max
  path = config.paths['log'].first

  # Add the log file to the list of appenders
  # Use the colorized formatter if Rails colorized logs are enabled
  ap_options = config.rails_semantic_logger.ap_options
  formatter  = config.rails_semantic_logger.format
  formatter  = { color: { ap: ap_options } } if (formatter == :default) && (config.colorize_logging != false)

  # Set internal logger to log to file only, in case another appender experiences errors during writes
  appender                         = SemanticLogger::Appender::File.new(path, formatter: formatter)
  appender.name                    = 'SemanticLogger'
  SemanticLogger::Processor.logger = appender

  # Check for previous file or stdout loggers
  SemanticLogger.appenders.each do |app|
    next unless app.is_a?(SemanticLogger::Appender::File) || app.is_a?(SemanticLogger::Appender::IO)

    app.formatter = formatter
  end
  SemanticLogger.appenders << Chouette::SemanticLogger::Appender::RotatingFile.new(
    path,
    formatter: formatter,
    filter: config.rails_semantic_logger.filter,
    reopen_max: config.logger_reopen_max,
    reopen_size: config.logger_reopen_size
  )
  SemanticLogger::Logger.processor.start
end

# Webpacker uses ActiveSupport::Logger.new(STDOUT) to log its message when ran in command line.
# Unfortunately, rails_semantic_logger redefines ActiveSupport::Logger.new to return a SemanticLogger.
# By default, a SemanticLogger will only append in a log file. Therefore, the process will not display any output.
# To fix this, we redefine Webpacker.ensure_log_goes_to_stdout to make it use ruby Logger instead of
# ActiveSupport::Logger. Both have the same API but Logger is not redefined by SemanticLogger.
module Webpacker
  def self.ensure_log_goes_to_stdout
    old_logger = Webpacker.logger
    Webpacker.logger = Logger.new($stdout)
    yield
  ensure
    Webpacker.logger = old_logger
  end
end
