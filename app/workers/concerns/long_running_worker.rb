module Concerns::LongRunningWorker
  def self.included klass
    klass.sidekiq_options queue: 'long_run'
  end
end
