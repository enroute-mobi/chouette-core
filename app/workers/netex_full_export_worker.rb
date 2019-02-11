class NetexFullExportWorker
  include Sidekiq::Worker
  include Concerns::LongRunningWorker
  extend Concerns::FailingSupport

  # Workers
  # =======

  def perform(export_id)
    export = Export::NetexFull.find(export_id)
    export.run
  end
end
