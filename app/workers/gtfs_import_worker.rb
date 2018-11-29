class GtfsImportWorker
  include Sidekiq::Worker
  include Concerns::LongRunningWorker

  def perform(import_id)
    import = Import::Gtfs.find(import_id)
    begin
      import.import
    rescue
      import.failed!
    end
  end
end
