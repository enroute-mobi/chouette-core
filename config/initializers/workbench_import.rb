WorkbenchImportService.import_dir = SmartEnv.fetch('WORKBENCH_IMPORT_DIR'){ Rails.root.join 'tmp/workbench_import' }
FileUtils.mkdir_p WorkbenchImportService.import_dir
