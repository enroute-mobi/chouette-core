
class WorkbenchImportWorker
  module ObjectStateUpdater

    def resource entry
      @_resources ||= {}
      @_resources[entry.name] ||= workbench_import.resources.find_or_create_by(name: entry.name, resource_type: "referential")
    end

    def update_object_state entry, count
      workbench_import.update( total_steps: count )
      update_spurious entry
      update_foreign_lines entry
      update_missing_calendar entry
      update_wrong_calendar entry
    end

    private

    def update_foreign_lines entry
      return if entry.foreign_lines.empty?
      resource(entry).messages.create(
        criticity: :error,
        message_key: 'foreign_lines_in_referential',
        message_attributes: {
          'source_filename' => workbench_import.file.file.file,
          'foreign_lines'   => entry.foreign_lines.join(', ')
        })
      resource(entry).update status: :ERROR
    end

    def update_spurious entry
      return if entry.spurious.empty?
      resource(entry).messages.create(
        criticity: :error,
        message_key: 'inconsistent_zip_file',
        message_attributes: {
          'source_filename' => workbench_import.file.file.file,
          'spurious_dirs'   => entry.spurious.join(', ')
        })
      resource(entry).update status: :ERROR
    end

    def update_missing_calendar entry
      return unless entry.missing_calendar
      resource(entry).messages.create(
        criticity: :error,
        message_key: 'missing_calendar_in_zip_file',
        message_attributes: {
          'source_filename' => entry.name
        })
      resource(entry).update status: :ERROR
    end

    def update_wrong_calendar entry
      return unless entry.wrong_calendar
      resource(entry).messages.create(
        criticity: :error,
        message_key: 'wrong_calendar_in_zip_file',
        message_attributes: {
          'source_filename' => entry.name
        })
      resource(entry).update status: :ERROR
    end
  end
end
