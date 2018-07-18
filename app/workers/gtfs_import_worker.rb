class GtfsImportWorker
  include Sidekiq::Worker
  include Concerns::LongRunningWorker

  def perform(import_id)
    Import::Gtfs.find(import_id).import
  end
end
