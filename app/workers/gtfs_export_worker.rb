class GTFSExportWorker
  include Sidekiq::Worker
  include Concerns::LongRunningWorker

  attr_reader :gtfs_export

  # Workers
  # =======

  def perform(export_id)
    @entries = 0
    @gtfs_export ||= Export::Gtfs.find(export_id)

    gtfs_export.update(status: 'running', started_at: Time.now)
    gtfs_export.export
  rescue Exception => e
    logger.error e.message
    if gtfs_export
      gtfs_export.messages.create(criticity: :error, message_attributes: { text: e.message }, message_key: :full_text)
      gtfs_export.update( status: 'failed' )
    end
    raise
  rescue
    @gtfs_export.failed!
  end
end
