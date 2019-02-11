class Export::NetexFull < Export::Base
  include LocalExportSupport

  option :duration, required: true, type: :integer, default_value: 200

  def worker_class
    NetexFullExportWorker
  end

  def generate_export_file
  end
end
