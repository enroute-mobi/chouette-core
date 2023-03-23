if ENV['COVERBAND_REDIS_URL']
  Coverband.configure do |config|
    config.track_gems = true
    config.ignore += %w[config/application.rb config/boot.rb config/puma.rb bin/* config/environments/* lib/tasks/*]
  end
end

