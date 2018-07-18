module Concerns::ImportantWorker
  def self.included klass
    klass.sidekiq_options queue: 'high_priority'
  end
end
