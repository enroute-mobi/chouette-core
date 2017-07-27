WorkbenchImportWorker.config do | config |
  config.dir = ENV.fetch('WORKBENCH_IMPORT_DIR'){ Rails.root.join 'tmp/workbench_import' }

  FileUtils.mkdir_p config.dir rescue nil
end
