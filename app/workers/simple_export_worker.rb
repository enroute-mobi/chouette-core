class SimpleExportWorker
  include Sidekiq::Worker
  include Concerns::LongRunningWorker

  def perform(export_id)
    export = Export::Base.find(export_id)
    export.update(status: 'running', started_at: Time.now)
    export.call_exporter
    export.update(ended_at: Time.now)
  end
end
