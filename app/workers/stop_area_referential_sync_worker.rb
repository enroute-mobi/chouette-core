class StopAreaReferentialSyncWorker
  include Sidekiq::Worker

  def process_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)
  end

  def perform(stop_area_ref_sync_id)
    start_time    = process_time
    stop_ref_sync = StopAreaReferentialSync.find stop_area_ref_sync_id
    stop_ref_sync.run if stop_ref_sync.may_run?
    begin
      info = Stif::ReflexSynchronization.synchronize
      stop_ref_sync.successful info.merge({processing_time: process_time - start_time})
    rescue Exception => e
      stop_ref_sync.failed({
        error: e.message,
        processing_time: process_time - start_time
      })
    end
  end
end
