module Configurable
  
  module ClassMethods
    def config &blk
      blk ? blk.(configuration) : configuration
    end

    private
    def configuration
      @__configuration__ ||= Rails::Application::Configuration.new
    end
  end

  module InstanceMethods
    private

    def config
      self.class.config
    end
  end

  def self.included(into)
    into.extend ClassMethods
    into.send :include, InstanceMethods
  end
end
