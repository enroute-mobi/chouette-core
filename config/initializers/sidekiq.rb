class Sidekiq::Middleware::Server::Logging
  def call(worker, item, queue)
    begin
      start = Time.now
      logger.info("#{queue_name queue} # start")
      yield
      logger.info("#{queue_name queue} # done: #{elapsed(start)} sec")
    rescue Exception
      logger.info("#{queue_name queue} # fail: #{elapsed(start)} sec")
      raise
    end
  end

  private

  def queue_name queue
    '%-20.20s' % queue
  end
end

Sidekiq.configure_server do |config|
  if ENV["CHOUETTE_SIDEKIQ_CANCEL_SYNCS_ON_BOOT"]
    [
      LineReferentialSync.pending,
      StopAreaReferentialSync.pending
    ].each do |pendings|
      pendings.map { |sync| sync.failed({error: 'Failed by Sidekiq reboot', processing_time: 0}) }
    end
  end
  config.redis = { url: ENV.fetch('SIDEKIQ_REDIS_URL', 'redis://localhost:6379/12') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('SIDEKIQ_REDIS_URL', 'redis://localhost:6379/12') }
end

Sidekiq.default_worker_options = { retry: false }
