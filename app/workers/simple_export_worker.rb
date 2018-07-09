class SimpleExportWorker
  include Sidekiq::Worker

  def perform(export_id)
    export = Export::Base.find(export_id)
    export.do_call_exporter
  end
end
