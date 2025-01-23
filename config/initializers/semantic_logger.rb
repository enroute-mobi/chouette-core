# frozen_string_literal: true

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
